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
--- -- Server example with one target:
--- emitNet('exampleEvent', source, 'arg1', 'arg2')
--- -- Turns into:
--- TriggerClientEvent('resourcename:client:exampleEvent', source, 'arg1', 'arg2')
---
--- -- Server example with multiple targets:
--- emitNet('exampleEvent', { 1, 2, 3 }, 'arg1', 'arg2')
--- -- Turns into:
--- TriggerClientEvent('resourcename:client:exampleEvent', 1, 'arg1', 'arg2')
--- TriggerClientEvent('resourcename:client:exampleEvent', 2, 'arg1', 'arg2')
--- TriggerClientEvent('resourcename:client:exampleEvent', 3, 'arg1', 'arg2')
--- ```
--- @param name string Event name
--- @param ...? any Event arguments (Optional)
--- @ltbridge export: EmitNet
function EventEmitNet(name, ...)
    local eventName = GetEventName(name, true)
    if isServer then
        local target = ...

        ltassert(type(target) == 'table' or type(target) == 'number', 'EmitNet: invalid target type on event (%s) expected table or number, got %s',
            name, type(target))

        if type(target) == 'table' then
            for i = 1, #target do
                ltassert(type(target[i]) == 'number', 'EmitNet: invalid target type on event (%s) expected table of numbers, got %s', name,
                    type(target[i]))
                TriggerClientEvent(eventName, target[i], select(2, ...))
            end
        elseif type(target) == 'number' then
            TriggerClientEvent(eventName, target, select(2, ...))
        end
    else
        TriggerServerEvent(eventName, ...)
    end
end
