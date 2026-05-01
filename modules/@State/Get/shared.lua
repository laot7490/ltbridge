--- Get entity state value.
--- ```lua
--- local fuel = LT.State.Get(vehicle, 'fuel')
--- ```
--- @param entity number Entity handle
--- @param key string State key
--- @return any
--- @ltbridge export: Get
function GetState(entity, key)
    return Entity(entity).state[key]
end
