require "ApocBRAntiCheat/ApocBRAntiCheatShared"

local MODULE = ApocBRAntiCheat.MODULE
local pendingDisconnect = nil

ApocBRAntiCheat.captureLuaCanaries()

local function buildState(player, flagsBefore, changed)
    return {
        access = ApocBRAntiCheat.getAccessLevel(player),
        changed = changed == true,
        flags = ApocBRAntiCheat.flagsToString(flagsBefore),
        hasCheats = ApocBRAntiCheat.hasProtectedCheats(player),
    }
end

local function clearLocalFlags(reason, requestId)
    local player = getPlayer()
    if player == nil or ApocBRAntiCheat.isPrivileged(player) then
        return
    end

    local flagsBefore = ApocBRAntiCheat.collectProtectedCheats(player)
    local changed = #flagsBefore > 0
    if changed then
        ApocBRAntiCheat.clearProtectedCheats(player)
        sendPlayerExtraInfo(player)
    end

    local args = buildState(player, flagsBefore, changed)
    args.reason = reason or "server_request"
    args.requestId = requestId or "client_self_check"
    sendClientCommand(MODULE, ApocBRAntiCheat.CMD_CLEAR_ACK, args)
end

local function selfCheck()
    local player = getPlayer()
    if player == nil or ApocBRAntiCheat.isPrivileged(player) then
        return
    end

    if ApocBRAntiCheat.hasProtectedCheats(player) then
        clearLocalFlags("client_self_check", "client_self_check")
    end
end

local function sendLivenessAck(payload)
    local challenge = ApocBRAntiCheat.unpackChallenge(payload)
    local player = getPlayer()
    if challenge == nil or player == nil then
        return
    end

    sendClientCommand(MODULE, ApocBRAntiCheat.CMD_LIVENESS_ACK, {
        p = ApocBRAntiCheat.packAck(challenge, player),
    })
end

local function openTicketFromServer(args)
    local player = getPlayer()
    if player == nil or addTicket == nil then
        return
    end

    local message = tostring(args and args.message or "ApocBRAntiCheat liveness verification failed")
    pcall(addTicket, player:getUsername(), message, -1)
end

local function disconnectFromServer(args)
    print("[ApocBRAntiCheat] disconnect requested by server: " .. tostring(args and args.reason or "liveness verification failed"))

    openTicketFromServer(args)
    pendingDisconnect = {
        ticks = 30,
    }
end

local function processPendingDisconnect()
    if pendingDisconnect == nil then
        return
    end

    pendingDisconnect.ticks = pendingDisconnect.ticks - 1
    if pendingDisconnect.ticks > 0 then
        return
    end

    pendingDisconnect = nil
    if forceDisconnect ~= nil then
        pcall(forceDisconnect)
        return
    end

    if disconnect ~= nil then
        pcall(disconnect)
    end
end

local function onServerCommand(module, command, args)
    if module ~= MODULE then
        return
    end

    if command == ApocBRAntiCheat.CMD_LIVENESS_CHALLENGE then
        sendLivenessAck(args and args.p)
        return
    end

    if command == ApocBRAntiCheat.CMD_OPEN_TICKET then
        openTicketFromServer(args)
        return
    end

    if command == ApocBRAntiCheat.CMD_DISCONNECT then
        disconnectFromServer(args)
        return
    end

    if command == ApocBRAntiCheat.CMD_CLEAR_LOCAL then
        clearLocalFlags(
            args and args.reason or "server_request",
            args and args.requestId or "server_request"
        )
    end
end

Events.OnServerCommand.Add(onServerCommand)
Events.OnTick.Add(processPendingDisconnect)
Events.EveryOneMinute.Add(selfCheck)
