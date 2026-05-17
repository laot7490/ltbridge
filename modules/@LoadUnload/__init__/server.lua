--- Execute a callback when a player loads.
--- @param cb fun()
--- ```lua
--- LT.OnPlayerLoad(function()
---     local src = source
---     print("Player loaded: ".. src)
--- end)
--- ```
--- @ltbridge global
function OnPlayerLoad(cb)
    local eventName = __LT_RESOURCE_NAME..':server:@LoadUnload:Loaded'
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, cb)
end

--- Execute a callback when a player unloads/drops.
--- @param cb fun()
--- ```lua
--- LT.OnPlayerUnload(function()
---     local src = source
---     print("Player disconnected: ".. src)
--- end)
--- ```
--- @ltbridge global
function OnPlayerUnload(cb)
    AddEventHandler('playerDropped', cb)
end