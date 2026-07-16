require "ApocBRAntiCheat/ApocBRAntiCheatShared"
require "ApocBRAntiCheat/ApocBRAntiCheatThresholdFile"

local MODULE = ApocBRAntiCheat.MODULE
local violations = {}
local pendingRequests = {}
local pendingLiveness = {}
local expiredLiveness = {}
local livenessFailures = {}
local lastRequestId = 0
local lastLivenessId = 0
local CLEAN_ACKS_TO_RESET = 10
local LIVENESS_ACTIVE_TICKS = 2
local LIVENESS_GRACE_TICKS = 3

local function getSandboxInt(name, defaultValue, minValue, maxValue)
    local value = defaultValue
    if SandboxVars ~= nil and SandboxVars[name] ~= nil then
        value = tonumber(SandboxVars[name]) or defaultValue
    end

    value = math.floor(value)
    if minValue ~= nil and value < minValue then
        value = minValue
    end
    if maxValue ~= nil and value > maxValue then
        value = maxValue
    end
    return value
end

local function getFailureThreshold()
    return getSandboxInt("ApocBRAntiCheatFailureTicketThreshold", 50, 1, 1000)
end

local function shouldKickOnFailureThreshold()
    return SandboxVars ~= nil and SandboxVars.ApocBRAntiCheatKickOnFailureThreshold == true
end

local function getUsername(player)
    if player == nil then
        return "unknown"
    end
    return player:getUsername() or "unknown"
end

local function nextRequestId()
    lastRequestId = lastRequestId + 1
    return tostring(lastRequestId)
end

local function nextLivenessId()
    lastLivenessId = (lastLivenessId + 1) % 65536
    if lastLivenessId == 0 then
        lastLivenessId = 1
    end
    return lastLivenessId
end

local function nextNonce(player, requestId)
    local x = player and math.floor(player:getX()) or 0
    local y = player and math.floor(player:getY()) or 0
    return ApocBRAntiCheat.mix16(requestId, x, y, ApocBRAntiCheat.getMinuteBucket(), 0, 0)
end

local function inBrackets(s)
    return "[" .. tostring(s) .. "]"
end

local function getPlayerLocation(player)
    if player == nil then
        return "unknown"
    end

    return string.format(
        "%d,%d,%d",
        math.floor(player:getX()),
        math.floor(player:getY()),
        math.floor(player:getZ())
    )
end

local function getFailureState(username)
    local state = livenessFailures[username]
    if state == nil then
        state = {
            count = 0,
            cleanAckStreak = 0,
            ticketed = false,
            kicked = false,
        }
        livenessFailures[username] = state
    end
    return state
end

local function openFailureTicket(player, state)
    local username = getUsername(player)
    local message = string.format(
        "[ApocBRAntiCheat] Player reached liveness failure threshold. failures=%d lastReason=%s lastDetail=%s location=%s",
        state.count,
        tostring(state.lastReason or "unknown"),
        tostring(state.lastDetail or "none"),
        getPlayerLocation(player)
    )
    state.lastTicketMessage = message

    local ok = false
    if ServerWorldDatabase ~= nil and ServerWorldDatabase.instance ~= nil then
        ok = pcall(function()
            ServerWorldDatabase.instance:addTicket(username, message, -1)
        end)
    end

    if (not ok) and addTicket ~= nil and isClient ~= nil and isClient() then
        ok = pcall(addTicket, username, message, -1)
    end

    local wroteThresholdFile = nil
    if ApocBRAntiCheatThresholdFile ~= nil then
        wroteThresholdFile = ApocBRAntiCheatThresholdFile.append(player, state.lastReason)
    end

    if not ok then
        pcall(sendServerCommand, player, MODULE, ApocBRAntiCheat.CMD_OPEN_TICKET, {
            message = message,
        })
    end

    print(string.format(
        "[ApocBRAntiCheat] liveness failure ticket %s for %s failures=%d reason=%s",
        ok and "created" or "fallback_requested",
        username,
        state.count,
        tostring(state.lastReason or "unknown")
    ))

    if wroteThresholdFile ~= nil then
        print(string.format(
            "[ApocBRAntiCheat] liveness threshold file write %s for %s file=%s",
            wroteThresholdFile and "created" or "failed",
            username,
            tostring(ApocBRAntiCheatThresholdFile.FILE_NAME)
        ))
    end

    state.ticketed = true
end

local function kickForFailureThreshold(player, state)
    if player == nil or state.kicked then
        return
    end

    local username = getUsername(player)
    local reason = "ApocBRAntiCheat liveness verification failed"
    local ok = false

    if GameServer ~= nil and GameServer.getConnectionFromPlayer ~= nil then
        local callOk, sent = pcall(function()
            local connection = GameServer.getConnectionFromPlayer(player)
            if connection == nil then
                return false
            end

            if GameServer.kick ~= nil then
                GameServer.kick(connection, "UI_Policy_KickReason", reason)
            end
            if connection.forceDisconnect ~= nil then
                connection:forceDisconnect("apocbr-anticheat-liveness")
            end
            return true
        end)
        ok = callOk and sent == true
    end

    if not ok then
        pcall(sendServerCommand, player, MODULE, ApocBRAntiCheat.CMD_DISCONNECT, {
            reason = reason,
            message = state.lastTicketMessage,
        })
    end

    print(string.format(
        "[ApocBRAntiCheat] liveness threshold kick %s for %s failures=%d",
        ok and "sent" or "fallback_requested",
        username,
        state.count
    ))

    state.kicked = true
end

local function recordLivenessFailure(player, reason, detail)
    if player == nil or ApocBRAntiCheat.isPrivileged(player) then
        return
    end

    local username = getUsername(player)
    local state = getFailureState(username)
    state.count = state.count + 1
    state.cleanAckStreak = 0
    state.lastReason = reason
    state.lastDetail = detail
    state.lastLocation = getPlayerLocation(player)

    local threshold = getFailureThreshold()
    print(string.format(
        "[ApocBRAntiCheat] liveness failure for %s count=%d threshold=%d reason=%s detail=%s",
        username,
        state.count,
        threshold,
        tostring(reason),
        tostring(detail or "none")
    ))

    if state.count >= threshold then
        if not state.ticketed then
            openFailureTicket(player, state)
        end
        if shouldKickOnFailureThreshold() then
            kickForFailureThreshold(player, state)
        end
    end
end

local function recordCleanLivenessAck(player)
    if player == nil then
        return
    end

    local username = getUsername(player)
    local state = livenessFailures[username]
    if state == nil or state.count <= 0 then
        return
    end

    state.cleanAckStreak = (state.cleanAckStreak or 0) + 1
    if state.cleanAckStreak < CLEAN_ACKS_TO_RESET then
        print(string.format(
            "[ApocBRAntiCheat] clean liveness ack streak for %s streak=%d/%d failures=%d",
            username,
            state.cleanAckStreak,
            CLEAN_ACKS_TO_RESET,
            state.count
        ))
        return
    end

    print(string.format(
        "[ApocBRAntiCheat] liveness failures reset for %s after %d clean ack challenges",
        username,
        CLEAN_ACKS_TO_RESET
    ))

    state.count = 0
    state.cleanAckStreak = 0
    state.lastReason = nil
    state.lastDetail = nil
    state.lastLocation = nil
    state.ticketed = false
    state.kicked = false
end

local function inspectLivenessAck(player, ack)
    local hasLivenessIssue = false
    if ack.flags ~= 0 then
        print(string.format(
            "[ApocBRAntiCheat] liveness ack reported protected flags from %s requestId=%s mask=%s access=%s",
            getUsername(player),
            tostring(ack.requestId),
            tostring(ack.flags),
            tostring(ack.access)
        ))
        recordLivenessFailure(player, "protected_flags", "mask=" .. tostring(ack.flags))
        hasLivenessIssue = true
    end

    if ack.surface ~= 0 then
        print(string.format(
            "[ApocBRAntiCheat] liveness ack reported suspicious lua surface from %s requestId=%s mask=%s",
            getUsername(player),
            tostring(ack.requestId),
            tostring(ack.surface)
        ))
        recordLivenessFailure(player, "suspicious_lua_surface", "mask=" .. tostring(ack.surface))
        hasLivenessIssue = true
    end

    return hasLivenessIssue
end


local function recordViolation(player, flags)
    local username = getUsername(player)
    local state = violations[username]
    if state == nil then
        state = { count = 0 }
        violations[username] = state
    end

    state.count = state.count + 1
    state.lastFlags = ApocBRAntiCheat.flagsToString(flags)
    state.lastAccess = ApocBRAntiCheat.getAccessLevel(player)

    local logText = ""
    if ISLogSystem.steamID then
        logText = logText .. inBrackets(ISLogSystem.steamID)
    end

    
    logText = logText .. inBrackets("AntiCheat")
    logText = logText .. inBrackets(username)
    logText = logText .. inBrackets(
        math.floor(player:getX()) .. "," ..
        math.floor(player:getY()) .. "," ..
        math.floor(player:getZ())
    )

    ISLogSystem.sendLog(player, "ClientActionLog", logText)

    print(string.format(
        "[ApocBRAntiCheat] cleared protected flags for %s access=%s count=%d flags=%s",
        username,
        state.lastAccess,
        state.count,
        state.lastFlags
    ))
end

local function requestClientCleanup(player, reason, flags)
    local requestId = nextRequestId()
    local username = getUsername(player)
    pendingRequests[requestId] = {
        username = username,
        age = 0,
        flags = ApocBRAntiCheat.flagsToString(flags),
    }

    local args = {
        requestId = requestId,
        reason = reason,
        flags = ApocBRAntiCheat.flagsToString(flags),
    }
    sendServerCommand(player, MODULE, ApocBRAntiCheat.CMD_CLEAR_LOCAL, args)
end

local function requestLiveness(player)
    if player == nil or ApocBRAntiCheat.isPrivileged(player) then
        return
    end

    local requestId = nextLivenessId()
    local nonce = nextNonce(player, requestId)
    local username = getUsername(player)
    pendingLiveness[requestId] = {
        username = username,
        player = player,
        nonce = nonce,
        age = 0,
    }

    sendServerCommand(player, MODULE, ApocBRAntiCheat.CMD_LIVENESS_CHALLENGE, {
        p = ApocBRAntiCheat.packChallenge(requestId, nonce, ApocBRAntiCheat.getMinuteBucket()),
    })
end

local function enforcePlayer(player)
    if player == nil or ApocBRAntiCheat.isPrivileged(player) then
        return
    end

    if not ApocBRAntiCheat.hasProtectedCheats(player) then
        return
    end

    local flags = ApocBRAntiCheat.collectProtectedCheats(player)
    ApocBRAntiCheat.clearProtectedCheats(player)
    recordViolation(player, flags)
    requestClientCleanup(player, "server_enforced", flags)
end

local function auditPendingRequests()
    if isClient() then 
        return
    end
    for requestId, request in pairs(pendingRequests) do
        request.age = request.age + 1
        if request.age >= 2 then
            print(string.format(
                "[ApocBRAntiCheat] missing client cleanup ack from %s requestId=%s flags=%s",
                request.username,
                requestId,
                request.flags
            ))
            pendingRequests[requestId] = nil
        end
    end

    for requestId, request in pairs(pendingLiveness) do
        request.age = request.age + 1
        if request.age >= LIVENESS_ACTIVE_TICKS then
            print(string.format(
                "[ApocBRAntiCheat] liveness ack grace started for %s requestId=%s",
                request.username,
                tostring(requestId)
            ))
            request.graceAge = 0
            expiredLiveness[requestId] = request
            pendingLiveness[requestId] = nil
        end
    end

    for requestId, request in pairs(expiredLiveness) do
        request.graceAge = (request.graceAge or 0) + 1
        if request.graceAge >= LIVENESS_GRACE_TICKS then
            print(string.format(
                "[ApocBRAntiCheat] missing liveness ack from %s requestId=%s grace=%d",
                request.username,
                tostring(requestId),
                request.graceAge
            ))
            recordLivenessFailure(request.player, "missing_ack", "requestId=" .. tostring(requestId))
            expiredLiveness[requestId] = nil
        end
    end
end

local function antiCheatHook()
    auditPendingRequests()

    local players = getOnlinePlayers()
    if players == nil then
        return
    end

    for i = 0, players:size() - 1 do
        local player = players:get(i)
        enforcePlayer(player)
        requestLiveness(player)
    end
end

local function onClientCommand(module, command, player, args)
    if module == "EtherDebug" and player ~= nil and not ApocBRAntiCheat.isPrivileged(player) then
        print(string.format(
            "[ApocBRAntiCheat] suspicious EtherDebug command from %s command=%s",
            getUsername(player),
            tostring(command)
        ))
        recordLivenessFailure(player, "unexpected_debug_command", tostring(command))
        return
    end

    if module ~= MODULE or player == nil then
        return
    end

    if command == ApocBRAntiCheat.CMD_CLEAR_ACK then
        local requestId = tostring(args and args.requestId or "")
        if pendingRequests[requestId] ~= nil then
            pendingRequests[requestId] = nil
        end

        print(string.format(
            "[ApocBRAntiCheat] client cleanup ack from %s requestId=%s access=%s changed=%s flags=%s reason=%s stillHasCheats=%s",
            getUsername(player),
            requestId,
            tostring(args and args.access or "unknown"),
            tostring(args and args.changed or false),
            tostring(args and args.flags or "none"),
            tostring(args and args.reason or "unknown"),
            tostring(args and args.hasCheats or false)
        ))
        return
    end

    if command == ApocBRAntiCheat.CMD_LIVENESS_ACK then
        local ack = ApocBRAntiCheat.unpackAck(args and args.p)
        if ack == nil then
            print(string.format(
                "[ApocBRAntiCheat] invalid liveness ack from %s",
                getUsername(player)
            ))
            recordLivenessFailure(player, "invalid_ack", "payload")
            return
        end

        local request = pendingLiveness[ack.requestId]
        if request == nil then
            request = expiredLiveness[ack.requestId]
            if request ~= nil then
                if request.username ~= getUsername(player) or request.nonce ~= ack.nonce then
                    print(string.format(
                        "[ApocBRAntiCheat] mismatched late liveness ack from %s requestId=%s",
                        getUsername(player),
                        tostring(ack.requestId)
                    ))
                    recordLivenessFailure(player, "mismatched_ack", "requestId=" .. tostring(ack.requestId))
                    expiredLiveness[ack.requestId] = nil
                    return
                end

                expiredLiveness[ack.requestId] = nil
                local hasLivenessIssue = inspectLivenessAck(player, ack)
                if not hasLivenessIssue then
                    print(string.format(
                        "[ApocBRAntiCheat] late liveness ack tolerated from %s requestId=%s",
                        getUsername(player),
                        tostring(ack.requestId)
                    ))
                end
                return
            end

            print(string.format(
                "[ApocBRAntiCheat] unexpected liveness ack from %s requestId=%s",
                getUsername(player),
                tostring(ack.requestId)
            ))
            recordLivenessFailure(player, "unexpected_ack", "requestId=" .. tostring(ack.requestId))
            return
        end

        if request.username ~= getUsername(player) or request.nonce ~= ack.nonce then
            print(string.format(
                "[ApocBRAntiCheat] mismatched liveness ack from %s requestId=%s",
                getUsername(player),
                tostring(ack.requestId)
            ))
            recordLivenessFailure(player, "mismatched_ack", "requestId=" .. tostring(ack.requestId))
            pendingLiveness[ack.requestId] = nil
            return
        end

        pendingLiveness[ack.requestId] = nil
        local hasLivenessIssue = inspectLivenessAck(player, ack)
        if not hasLivenessIssue then
            recordCleanLivenessAck(player)
        end
    end
end

Events.OnClientCommand.Add(onClientCommand)
Events.EveryOneMinute.Add(antiCheatHook)
