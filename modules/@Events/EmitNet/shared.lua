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
--- -- Turns into:
--- TriggerServerEvent('resourcename:server:exampleEvent', 'arg1', 'arg2')
---
--- -- Server example:
--- emitNet('exampleEvent', source, 'arg1', 'arg2')
--- -- Turns into:
--- TriggerClientEvent('resourcename:client:exampleEvent', source, 'arg1', 'arg2')
--- ```
--- @param name string Event name
--- @param ...? any Event arguments (Optional)
--- @ltbridge export: EmitNet
function EventEmitNet(name, ...)
    local eventName = GetEventName(name, true)
    if isServer then
        local args = { ... }
        local target = args[1]

        if type(target) ~= 'number' then
            return printf(
                'error',
                'EmitNet: invalid target on event (%s)',
                name
            )
        end

        table.remove(args, 1)

        TriggerClientEvent(eventName, target, table.unpack(args))
    else
        TriggerServerEvent(eventName, ...)
    end
end
