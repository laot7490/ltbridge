local os_time = os.time
local lastTriggerTime = {}

--- Start a cooldown for a specific player and key.
--- ```lua
--- LT.Cooldown.Start(source, 'gather', 5000) -- 5 seconds
--- ```
--- @param source string|number Player Server ID
--- @param key string Cooldown identifier
--- @param durationMs number Cooldown duration in milliseconds
--- @ltbridge export: Start
function StartCooldown(source, key, durationMs)
    if not source or not key then return end
    local srcStr = tostring(source)
    if not lastTriggerTime[srcStr] then lastTriggerTime[srcStr] = {} end
    
    local durationSec = durationMs / 1000
    lastTriggerTime[srcStr][key] = os_time() + durationSec
end

--- Check if a specific cooldown is active.
--- ```lua
--- if LT.Cooldown.Check(source, 'gather') then return end
--- ```
--- @param source string|number Player Server ID
--- @param key string Cooldown identifier
--- @return boolean
--- @ltbridge export: Check
function CheckCooldown(source, key)
    if not source or not key then return false end
    local srcStr = tostring(source)
    
    if not lastTriggerTime[srcStr] or not lastTriggerTime[srcStr][key] then
        return false
    end
    
    if os_time() < lastTriggerTime[srcStr][key] then
        return true
    end
    
    -- Cleanup expired
    lastTriggerTime[srcStr][key] = nil
    return false
end

--- Get remaining cooldown time in milliseconds.
--- @param source string|number Player Server ID
--- @param key string Cooldown identifier
--- @return number remainingMs
--- @ltbridge export: Remaining
function GetCooldownRemaining(source, key)
    if not source or not key then return 0 end
    local srcStr = tostring(source)
    
    if not lastTriggerTime[srcStr] or not lastTriggerTime[srcStr][key] then
        return 0
    end
    
    local remaining = lastTriggerTime[srcStr][key] - os_time()
    if remaining > 0 then
        return math.floor(remaining * 1000)
    end
    
    lastTriggerTime[srcStr][key] = nil
    return 0
end

--- Clear a specific cooldown early.
--- @param source string|number Player Server ID
--- @param key string Cooldown identifier
--- @ltbridge export: Clear
function ClearCooldown(source, key)
    if not source or not key then return end
    local srcStr = tostring(source)
    if lastTriggerTime[srcStr] then
        lastTriggerTime[srcStr][key] = nil
    end
end

-- Cleanup when player drops to prevent memory leaks
AddEventHandler('playerDropped', function()
    local srcStr = tostring(source)
    if lastTriggerTime[srcStr] then
        lastTriggerTime[srcStr] = nil
    end
end)
