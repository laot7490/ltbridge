--- Set entity state value.
--- ```lua
--- LT.State.Set(vehicle, 'fuel', 100.0)
--- LT.State.Set(ped, 'busy', true, false) -- not replicated
--- ```
--- @param entity number Entity handle
--- @param key string State key
--- @param value any State value
--- @param replicated? boolean Replicate to network (default: true)
--- @ltbridge export: Set
function SetState(entity, key, value, replicated)
    Entity(entity).state:set(key, value, replicated ~= false)
end
