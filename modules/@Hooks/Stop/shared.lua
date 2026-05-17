--- Execute a callback when a resource stops.
--- @param cb fun()
--- @param resource? string Defaults to the current resource name.
--- ```lua
--- LT.Hooks.Stop(function()
---     print("Resource stopped.")
--- end)
--- ```
--- @ltbridge export: Stop
function OnResourceStop(cb, resource)
    local checkResource = resource or __LT_RESOURCE_NAME
    AddEventHandler('onResourceStop', function (res)
        if res ~= checkResource then return end
        cb()
    end)
end