--- Execute a callback when a player loads.
--- @param cb fun()
--- ```lua
--- LT.OnPlayerLoad(function()
---     print("Player loaded.")
--- end)
--- ```
--- @ltbridge global
function OnPlayerLoad(cb)
    CreateThread(function()
        while not IsPlayerLoaded() do
            Wait(100)
        end
        cb()
    end)
end

CreateThread(function()
    while not IsPlayerLoaded() do
        Wait(100)
    end
    TriggerServerEvent(LT_RESOURCE_NAME..':server:@LoadUnload:Loaded')
end)