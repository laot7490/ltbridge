local os_time = os.time
local lastTriggerTime = {}

--- Start a cooldown for a specific identifier and key.
--- ```lua
--- local citizenId = LT.Framework.GetPlayerCitizenId(source)
--- LT.Cooldown.Start(citizenId, 'gather', 5000) -- 5 seconds
--- ```
--- @param identifier string|number Cooldown identifier (like player citizenid)
--- @param key string Cooldown identifier
--- @param duration number Cooldown duration in milliseconds
--- @ltbridge export: Start
function StartCooldown(identifier, key, duration)
    if not identifier or not key then return end
    local identifierSrc = tostring(identifier)
    if not lastTriggerTime[identifierSrc] then lastTriggerTime[identifierSrc] = {} end

    local durationInSeconds = duration / 1000
    lastTriggerTime[identifierSrc][key] = os_time() + durationInSeconds
end

--- Check if a specific cooldown is active.
--- ```lua
--- local citizenId = LT.Framework.GetPlayerCitizenId(source)
--- if LT.Cooldown.Check(citizenId, 'gather') then return end
--- ```
--- @param identifier string|number Cooldown identifier (like player citizenid)
--- @param key string Cooldown identifier
--- @return boolean
--- @ltbridge export: Check
function CheckCooldown(identifier, key)
    if not identifier or not key then return false end
    local identifierSrc = tostring(identifier)

    if not lastTriggerTime[identifierSrc] or not lastTriggerTime[identifierSrc][key] then
        return false
    end

    if os_time() < lastTriggerTime[identifierSrc][key] then
        return true
    end

    -- Cleanup expired
    lastTriggerTime[identifierSrc][key] = nil
    return false
end

--- Get remaining cooldown time in milliseconds.
--- @param identifier string|number Cooldown identifier (like player citizenid)
--- @param key string Cooldown identifier
--- @return number remainingMs
--- @ltbridge export: Remaining
function GetCooldownRemaining(identifier, key)
    if not identifier or not key then return 0 end
    local identifierSrc = tostring(identifier)

    if not lastTriggerTime[identifierSrc] or not lastTriggerTime[identifierSrc][key] then
        return 0
    end

    local remaining = lastTriggerTime[identifierSrc][key] - os_time()
    if remaining > 0 then
        return math.floor(remaining * 1000)
    end

    lastTriggerTime[identifierSrc][key] = nil
    return 0
end

--- Clear a specific cooldown early.
--- @param identifier string|number Cooldown identifier (like player citizenid)
--- @param key string Cooldown identifier
--- @ltbridge export: Clear
function ClearCooldown(identifier, key)
    if not identifier or not key then return end
    local identifierSrc = tostring(identifier)
    if lastTriggerTime[identifierSrc] then
        lastTriggerTime[identifierSrc][key] = nil
    end
end

--- Cleanup expired cooldowns to prevent memory leaks.
CreateThread(function()
    while true do
        if next(lastTriggerTime) then
            for identifier, data in pairs(lastTriggerTime) do
                for key, time in pairs(data) do
                    if os_time() > time then
                        lastTriggerTime[identifier][key] = nil
                    end
                end
            end
        else
            Wait(120000) -- 2 minutes
        end
        Wait(60000)      -- 1 minute
    end
end)
