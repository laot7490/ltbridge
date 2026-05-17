--- Execute a callback when a resource starts.
--- @param cb fun()
--- @param resource? string Defaults to the current resource name.
--- ```lua
--- LT.Hooks.Start(function()
---     print("Resource started.")
--- end)
--- ```
--- @ltbridge export: Start
function OnResourceStart(cb, resource)
    local checkResource = resource or __LT_RESOURCE_NAME
    AddEventHandler('onResourceStart', function (res)
        if res ~= checkResource then return end
        cb()
    end)
end