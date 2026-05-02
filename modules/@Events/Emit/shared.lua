--- Triggers local event with formatted name.
--- **Lua Example:**
--- ```lua
--- local emit = LT.Events.Emit
--- 
--- -- Client example:
--- emit('event', 'arg1', 'arg2')
--- ```
--- @param name string Event name
--- @param ...? any Event arguments (Optional)
--- @ltbridge export: Emit
function EventEmit(name, ...)
    TriggerEvent(GetEventName(name), ...)
end