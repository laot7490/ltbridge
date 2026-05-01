local isServer <const> = IsDuplicityVersion()

--- Triggers network event with formatted name.
--- 
--- `Client` -> `Server`
--- 
--- `Server` -> `Client`
--- 
--- **Lua Example:**
--- ```lua
--- local emitNet = LT.Events.EmitNet
--- 
--- -- Client example:
--- emitNet('exampleEvent', 'arg1', 'arg2')
--- 
--- -- Server example:
--- emitNet('exampleEvent', source, 'arg1', 'arg2')
--- ```
--- @param name string Event name
--- @param ...? any
--- @ltbridge export: EmitNet
function EventEmitNet(name, ...)
    local eventName = GetEventName(name, true)
    if isServer then
        local args = {...}
        local target = args[1]
        
        if type(target) ~= 'number' then
            local info = debug.getinfo(2, "Sl")

            return printf(
                'error',
                'EmitNet: invalid target on event (%s) [%s:%d]',
                name,
                info.short_src or info.source,
                info.currentline or -1
            )
        end

        table.remove(args, 1)
        
        TriggerClientEvent(eventName, target, table.unpack(args))
    else
        TriggerServerEvent(eventName, ...)
    end
end