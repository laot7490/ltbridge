local RegisterNUICallback = RegisterNUICallback
--- Registers a NUI callback/listener.
--- ```lua
--- LT.NUI.Callback('closeMenu', function(data, cb)
---     LT.NUI.Focus(false)
---     cb('ok')
--- end)
--- ```
--- @param name string Callback name
--- @param cb fun(data: table, cb: fun(response: any))
--- @ltbridge export: Callback
function NUICallback(name, cb)
    RegisterNUICallback(name, cb)
end
