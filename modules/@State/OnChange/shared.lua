--- Register a handler for state bag changes across all entities.
--- ```lua
--- LT.State.OnChange('fuel', function(value, bagName)
---     local entity = GetEntityFromStateBagName(bagName)
---     if entity > 0 then
---         print(('Entity %s fuel changed to %s'):format(entity, value))
---     end
--- end)
--- ```
--- @param key string State key to watch
--- @param handler fun(value: any, bagName: string)
--- @return number Handler ID (use RemoveStateBagChangeHandler to remove)
--- @ltbridge export: OnChange
function OnStateChange(key, handler)
    --- @diagnostic disable-next-line
    return AddStateBagChangeHandler(key, nil, function(bagName, _, value)
        handler(value, bagName)
    end)
end
