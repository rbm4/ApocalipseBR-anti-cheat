ApocBRAntiCheatThresholdFile = ApocBRAntiCheatThresholdFile or {}

ApocBRAntiCheatThresholdFile.FILE_NAME = "ApocBRAntiCheat_threshold_failures.csv"

local function cleanCsvField(value)
    value = tostring(value or "unknown")
    value = string.gsub(value, "[\r\n,]", " ")
    return value
end

local function getPlayerUsername(player)
    if player ~= nil and player.getUsername ~= nil then
        local ok, username = pcall(function()
            return player:getUsername()
        end)
        if ok and username ~= nil and tostring(username) ~= "" then
            return tostring(username)
        end
    end
    return "unknown"
end

function ApocBRAntiCheatThresholdFile.append(player, reason)
    if getFileWriter == nil then
        return false
    end

    local username = cleanCsvField(getPlayerUsername(player))
    reason = cleanCsvField(reason)
    local writer = getFileWriter(ApocBRAntiCheatThresholdFile.FILE_NAME, true, true)
    if writer == nil then
        return false
    end

    writer:write(username .. "," .. reason .. "\r\n")
    writer:close()
    return true
end
