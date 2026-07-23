ApocBRAntiCheat = ApocBRAntiCheat or {}

ApocBRAntiCheat.MODULE = "ApocBRAntiCheat"
ApocBRAntiCheat.CMD_CLEAR_LOCAL = "ClearLocalFlags"
ApocBRAntiCheat.CMD_CLEAR_ACK = "ClearLocalFlagsAck"
ApocBRAntiCheat.CMD_CLIENT_STATE = "ClientFlagState"
ApocBRAntiCheat.CMD_LIVENESS_CHALLENGE = "L1"
ApocBRAntiCheat.CMD_LIVENESS_ACK = "L2"
ApocBRAntiCheat.CMD_OPEN_TICKET = "T1"
ApocBRAntiCheat.CMD_DISCONNECT = "D1"
ApocBRAntiCheat.ACK_VERSION = 1
ApocBRAntiCheat.ACK_SECRET = 7139

ApocBRAntiCheat.ETHER_GLOBAL_FUNCTIONS = {
    getAntiCheat8Status = true,
    getAntiCheat12Status = true,
    getExtraTexture = true,
    hackAdminAccess = true,
    isDisableFakeInfectionLevel = true,
    isDisableInfectionLevel = true,
    isDisableWetness = true,
    isEnableUnlimitedCarry = true,
    isOptimalWeight = true,
    isOptimalCalories = true,
    isPlayerInSafeTeleported = true,
    learnAllRecipes = true,
    requireExtra = true,
    safePlayerTeleport = true,
    toggleEnableUnlimitedCarry = true,
    toggleOptimalWeight = true,
    toggleOptimalCalories = true,
    toggleDisableFakeInfectionLevel = true,
    toggleDisableInfectionLevel = true,
    toggleDisableWetness = true,

    ToggleDoor = true,
    Destroy = true,
    DestroyObject = true,
    CreateKeyVehicle = true,
    GodProvides = true,
    HasRequiredObject = true,
    MoveObject = true,
    DestroyVehicle = true,

    getZombieUIColor = true,
    setZombieUIColor = true,
    getVehicleUIColor = true,
    setVehicleUIColor = true,
    getPlayersUIColor = true,
    setPlayersUIColor = true,
    setAccentUIColor = true,
    getEtherUIWidth = true,
    getEtherUIHeight = true,
    saveEtherUISize = true,
    deleteConfig = true,
    getConfigList = true,
    loadConfig = true,
    saveConfig = true,
    giveItem = true,
    isBypassDebugMode = true,
    toggleBypassDebugMode = true,
    isAlwaysRack = true,
    toggleAlwaysRack = true,
    isAlwaysRoundChamber = true,
    toggleAlwaysRoundChamber = true,
    isAlwaysKnockdown = true,
    toggleAlwaysKnockdown = true,
    isAlwaysAiming = true,
    toggleAlwaysAiming = true,
    isAlwaysCritical = true,
    toggleAlwaysCritical = true,
    isZombieDontAttack = true,
    toggleZombieDontAttack = true,
    isEnableNightVision = true,
    toggleNightVision = true,
    isNoRecoil = true,
    toggleNoRecoil = true,
    isNoReload = true,
    toggleNoReload = true,
    isNoJam = true,
    toggleNoJam = true,
    isNoSpentRoundChamber = true,
    toggleNoSpentRoundChamber = true,
    isAutoRepairItems = true,
    toggleAutoRepairItems = true,
    resetWeaponsStats = true,
    isTimedActionCheat = true,
    toggleTimedActionCheat = true,
    isMultiHitZombies = true,
    toggleMultiHitZombies = true,
    isUnlimitedCondition = true,
    toggleUnlimitedCondition = true,
    isMapDrawZombies = true,
    toggleMapDrawZombies = true,
    isMapDrawVehicles = true,
    toggleMapDrawVehicles = true,
    isMapDrawAllPlayers = true,
    toggleMapDrawAllPlayers = true,
    isMapDrawLocalPlayer = true,
    toggleMapDrawLocalPlayer = true,
    setZombieKills = true,
    setHoursAlive = true,
    getZombieKills = true,
    getHoursAlive = true,
    getAccentUIColor = true,
}

ApocBRAntiCheat.ETHER_GLOBAL_CLASSES = {
    EtherMain = true,
    EtherAdminMenu = true,
    EtherDebugMenu = true,
    EtherEditWorldObjects = true,
    EtherCharacterPanel = true,
    EtherExploitPanel = true,
    EtherInfoPanel = true,
    EtherItemCreator = true,
    EtherMapPanel = true,
    EtherPlayerEditor = true,
    EtherSettingsPanel = true,
    EtherVisualsPanel = true,

    DoorUnlock = true,
    EtherDebugClient = true,
    EtherDebugMenu = true,
    EtherEditInventoryItem = true,
    UIButtonsPanel = true,
    UICheckbox = true,
    UIButton = true,
    UISlider = true,
    UIMechanics = true,
    UIModalAddXP = true,
    UIMovableMiniMap = true,
    UIModalAddTrait = true,
    UIHealth = true,
    UIItemTables = true,
    UIMap = true,
    UISkillTable = true,
    UITraitsTable = true,
}

ApocBRAntiCheat.LUA_CANARY_TARGETS = {
    { owner = "ISWorldObjectContextMenu", field = "createMenu" },
    { owner = "ISVehicleMenu", field = "FillPartMenu" },
    { owner = "ISVehicleMenu", field = "showRadialMenu" },
    { owner = "ISBuildAction", field = "perform" },
    { owner = "ISBuildAction", field = "waitToStart" },
    { owner = "ISBuildIsoEntity", field = "create" },
    { owner = "ISBuildPanel", field = "createBuildIsoEntity" },
    { owner = "ISWidgetOutput", field = "updateValues" },
}

ApocBRAntiCheat.luaCanaries = ApocBRAntiCheat.luaCanaries or nil

ApocBRAntiCheat.ALLOWED_ACCESS = {
    admin = true,
    moderator = true,
}

local function lower(value)
    if value == nil then
        return "none"
    end
    return string.lower(tostring(value))
end

function ApocBRAntiCheat.getAccessLevel(player)
    if player == nil then
        return "none"
    end
    return lower(player:getAccessLevel() or "none")
end

function ApocBRAntiCheat.isPrivileged(player)
    return ApocBRAntiCheat.ALLOWED_ACCESS[ApocBRAntiCheat.getAccessLevel(player)] == true
end

function ApocBRAntiCheat.hasProtectedCheats(player)
    if player == nil then
        return false
    end

    return player:isGodMod()
        or player:isInvisible()
        or player:isGhostMode()
        or player:isNoClip()
        or player:isFastMoveCheat()
        or player:isUnlimitedCarry()
        or player:isUnlimitedEndurance()
        or player:isUnlimitedAmmo()
        or player:isTimedActionInstantCheat()
        or player:isZombiesDontAttack()
        or player:isInvincible()
        or player:isBuildCheat()
        or player:isFarmingCheat()
        or player:isHealthCheat()
        or player:isMechanicsCheat()
        or player:isMovablesCheat()
end

function ApocBRAntiCheat.collectProtectedCheats(player)
    local flags = {}
    if player == nil then
        return flags
    end

    if player:isGodMod() then table.insert(flags, "GodMod") end
    if player:isInvisible() then table.insert(flags, "Invisible") end
    if player:isGhostMode() then table.insert(flags, "GhostMode") end
    if player:isNoClip() then table.insert(flags, "NoClip") end
    if player:isFastMoveCheat() then table.insert(flags, "FastMove") end
    if player:isUnlimitedCarry() then table.insert(flags, "UnlimitedCarry") end
    if player:isUnlimitedEndurance() then table.insert(flags, "UnlimitedEndurance") end
    if player:isUnlimitedAmmo() then table.insert(flags, "UnlimitedAmmo") end
    if player:isTimedActionInstantCheat() then table.insert(flags, "TimedActionInstant") end
    if player:isZombiesDontAttack() then table.insert(flags, "ZombiesDontAttack") end
    if player:isInvincible() then table.insert(flags, "Invincible") end
    if player:isBuildCheat() then table.insert(flags, "BuildCheat") end
    if player:isFarmingCheat() then table.insert(flags, "FarmingCheat") end
    if player:isHealthCheat() then table.insert(flags, "HealthCheat") end
    if player:isMechanicsCheat() then table.insert(flags, "MechanicsCheat") end
    if player:isMovablesCheat() then table.insert(flags, "MovablesCheat") end

    return flags
end

function ApocBRAntiCheat.flagsToString(flags)
    if flags == nil or #flags == 0 then
        return "none"
    end
    return table.concat(flags, ",")
end

function ApocBRAntiCheat.collectProtectedCheatMask(player)
    if player == nil then
        return 0
    end

    local mask = 0
    if player:isGodMod() then mask = mask + 1 end
    if player:isInvisible() then mask = mask + 2 end
    if player:isGhostMode() then mask = mask + 4 end
    if player:isNoClip() then mask = mask + 8 end
    if player:isFastMoveCheat() then mask = mask + 16 end
    if player:isUnlimitedCarry() then mask = mask + 32 end
    if player:isUnlimitedEndurance() then mask = mask + 64 end
    if player:isUnlimitedAmmo() then mask = mask + 128 end
    if player:isTimedActionInstantCheat() then mask = mask + 256 end
    if player:isZombiesDontAttack() then mask = mask + 512 end
    if player:isInvincible() then mask = mask + 1024 end
    if player:isBuildCheat() then mask = mask + 2048 end
    if player:isFarmingCheat() then mask = mask + 4096 end
    if player:isHealthCheat() then mask = mask + 8192 end
    if player:isMechanicsCheat() then mask = mask + 16384 end
    if player:isMovablesCheat() then mask = mask + 32768 end

    return mask
end

function ApocBRAntiCheat.isSafeNameShape(name)
    if type(name) ~= "string" then
        return false
    end

    return string.match(name, "^_fn_%x%x%x%x%x%x%x%x$") ~= nil
        or string.match(name, "^lua_%x%x%x%x%x%x%x%x$") ~= nil
        or string.match(name, "^game_%x%x%x%x%x%x%x%x$") ~= nil
        or string.match(name, "^core_%x%x%x%x%x%x%x%x$") ~= nil
end

function ApocBRAntiCheat.captureLuaCanaries()
    local canaries = {}

    for _, target in ipairs(ApocBRAntiCheat.LUA_CANARY_TARGETS) do
        local owner = _G[target.owner]
        if type(owner) == "table" and type(owner[target.field]) == "function" then
            table.insert(canaries, {
                owner = target.owner,
                field = target.field,
                value = owner[target.field],
            })
        end
    end

    ApocBRAntiCheat.luaCanaries = canaries
end

function ApocBRAntiCheat.hasLuaCanaryChanged()
    if ApocBRAntiCheat.luaCanaries == nil or #ApocBRAntiCheat.luaCanaries == 0 then
        return false
    end

    for _, canary in ipairs(ApocBRAntiCheat.luaCanaries) do
        local owner = _G[canary.owner]
        if type(owner) == "table" and owner[canary.field] ~= canary.value then
            return true
        end
    end

    return false
end

function ApocBRAntiCheat.collectLuaSurfaceMask()
    local hasKnownFunction = false
    local hasKnownClass = false
    local safeNameCount = 0

    for name, value in pairs(_G) do
        local valueType = type(value)
        if not hasKnownFunction and ApocBRAntiCheat.ETHER_GLOBAL_FUNCTIONS[name] and valueType == "function" then
            hasKnownFunction = true
        end

        if not hasKnownClass and ApocBRAntiCheat.ETHER_GLOBAL_CLASSES[name] then
            hasKnownClass = true
        elseif not hasKnownClass and valueType == "table" and value.Type ~= nil and ApocBRAntiCheat.ETHER_GLOBAL_CLASSES[tostring(value.Type)] then
            hasKnownClass = true
        end

        if safeNameCount < 3
            and valueType == "function"
            and ApocBRAntiCheat.isSafeNameShape(name)
            and string.find(tostring(value), "function ") == 1 then
            safeNameCount = safeNameCount + 1
        end

        if hasKnownFunction and hasKnownClass and safeNameCount >= 3 then
            break
        end
    end

    local mask = 0
    if hasKnownFunction then
        mask = mask + 1
    end
    if hasKnownClass then
        mask = mask + 2
    end
    if safeNameCount >= 3 then
        mask = mask + 4
    end
    if ApocBRAntiCheat.hasLuaCanaryChanged() then
        mask = mask + 8
    end

    return mask
end

function ApocBRAntiCheat.getAccessCode(player)
    local access = ApocBRAntiCheat.getAccessLevel(player)
    if access == "admin" then return 1 end
    if access == "moderator" then return 2 end
    if access == "overseer" then return 3 end
    if access == "gm" then return 4 end
    if access == "observer" then return 5 end
    return 0
end

function ApocBRAntiCheat.getMinuteBucket()
    local now = 0
    if getTimestampMs ~= nil then
        now = getTimestampMs() or 0
    end
    return math.floor(now / 60000) % 65536
end

function ApocBRAntiCheat.mix16(a, b, c, d, e, f)
    local value = ApocBRAntiCheat.ACK_SECRET
    value = (value + (a or 0) * 131) % 65536
    value = (value + (b or 0) * 257) % 65536
    value = (value + (c or 0) * 521) % 65536
    value = (value + (d or 0) * 1031) % 65536
    value = (value + (e or 0) * 2053) % 65536
    value = (value + (f or 0) * 4099) % 65536
    return value
end

function ApocBRAntiCheat.packChallenge(requestId, nonce, bucket)
    local rid = tonumber(requestId) or 0
    local n = tonumber(nonce) or 0
    local t = tonumber(bucket) or ApocBRAntiCheat.getMinuteBucket()
    local sig = ApocBRAntiCheat.mix16(ApocBRAntiCheat.ACK_VERSION, rid, n, t, 0, 0)

    return string.format("%01X%04X%04X%04X%04X",
        ApocBRAntiCheat.ACK_VERSION,
        rid % 65536,
        n % 65536,
        t % 65536,
        sig
    )
end

function ApocBRAntiCheat.unpackChallenge(payload)
    if type(payload) ~= "string" or #payload ~= 17 then
        return nil
    end

    local version = tonumber(string.sub(payload, 1, 1), 16)
    local requestId = tonumber(string.sub(payload, 2, 5), 16)
    local nonce = tonumber(string.sub(payload, 6, 9), 16)
    local bucket = tonumber(string.sub(payload, 10, 13), 16)
    local sig = tonumber(string.sub(payload, 14, 17), 16)

    if version ~= ApocBRAntiCheat.ACK_VERSION then
        return nil
    end

    local expected = ApocBRAntiCheat.mix16(version, requestId, nonce, bucket, 0, 0)
    if sig ~= expected then
        return nil
    end

    return {
        requestId = requestId,
        nonce = nonce,
        bucket = bucket,
    }
end

function ApocBRAntiCheat.packAck(challenge, player)
    local flags = ApocBRAntiCheat.collectProtectedCheatMask(player)
    local access = ApocBRAntiCheat.getAccessCode(player)
    local surface = ApocBRAntiCheat.collectLuaSurfaceMask()
    local bucket = ApocBRAntiCheat.getMinuteBucket()
    local sig = ApocBRAntiCheat.mix16(
        ApocBRAntiCheat.ACK_VERSION,
        challenge.requestId,
        challenge.nonce,
        bucket,
        flags + surface,
        access
    )

    return string.format("%01X%04X%04X%04X%04X%04X%01X%04X",
        ApocBRAntiCheat.ACK_VERSION,
        challenge.requestId % 65536,
        challenge.nonce % 65536,
        bucket % 65536,
        flags % 65536,
        surface % 65536,
        access % 16,
        sig
    )
end

function ApocBRAntiCheat.unpackAck(payload)
    if type(payload) ~= "string" or #payload ~= 26 then
        return nil
    end

    local version = tonumber(string.sub(payload, 1, 1), 16)
    local requestId = tonumber(string.sub(payload, 2, 5), 16)
    local nonce = tonumber(string.sub(payload, 6, 9), 16)
    local bucket = tonumber(string.sub(payload, 10, 13), 16)
    local flags = tonumber(string.sub(payload, 14, 17), 16)
    local surface = tonumber(string.sub(payload, 18, 21), 16)
    local access = tonumber(string.sub(payload, 22, 22), 16)
    local sig = tonumber(string.sub(payload, 23, 26), 16)

    if version ~= ApocBRAntiCheat.ACK_VERSION then
        return nil
    end

    local expected = ApocBRAntiCheat.mix16(version, requestId, nonce, bucket, flags + surface, access)
    if sig ~= expected then
        return nil
    end

    return {
        requestId = requestId,
        nonce = nonce,
        bucket = bucket,
        flags = flags,
        surface = surface,
        access = access,
    }
end

function ApocBRAntiCheat.clearProtectedCheats(player)
    if player == nil then
        return
    end

    player:setGodMod(false)
    player:setInvisible(false)
    player:setGhostMode(false)
    player:setNoClip(false)
    player:setFastMoveCheat(false)
    player:setUnlimitedCarry(false)
    player:setUnlimitedEndurance(false)
    player:setUnlimitedAmmo(false)
    player:setTimedActionInstantCheat(false)
    player:setZombiesDontAttack(false)
    player:setInvincible(false)
    player:setBuildCheat(false)
    player:setFarmingCheat(false)
    player:setHealthCheat(false)
    player:setMechanicsCheat(false)
    player:setMovablesCheat(false)
end
