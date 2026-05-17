--- Set NUI focus and optional mouse cursor. Also triggers an event that can be listened to.
---
--- **Lua Example:**
--- ```lua
--- LT.NUI.Focus(true, true) -- Focus + Mouse
--- LT.NUI.Focus(false)      -- Close All
--- 
--- AddEventHandler(GetCurrentResourceName() .. ':client:@NUI:FocusChanged', function(status, cursor)
---     print('NUI Focus Changed:', status, cursor)
--- end)
--- ```
---
--- @param status boolean Focus status
--- @param cursor? boolean Optional mouse cursor status (defaults to status)
--- @ltbridge export: Focus
function NUIFocus(status, cursor)
    SetNuiFocus(status, (cursor == nil and status) or (type(cursor) == "boolean" and cursor))
    TriggerEvent(__LT_RESOURCE_NAME.. ':client:@NUI:FocusChanged', status, cursor)
end
