--- Register a event with formatted name.
--- **Lua Example:**
--- ```lua
--- local register = LT.Events.Register
--- 
--- -- Client example:
--- register('event', function(arg1, arg2)
---     print(arg1, arg2)
--- end)
--- 
--- -- Server example:
--- register('event', function(arg1, arg2)
---     local src = source
---     print(source, arg1, arg2)
--- end)
--- ```
--- @param name string Event name.
--- @param cb? function Callback function.
--- @ltbridge export: Register
function EventRegister(name, cb)
    local event = GetEventName(name)
    if cb and type(cb) == 'function' then
        RegisterNetEvent(event, cb)
    else
        RegisterNetEvent(event)
    end
end