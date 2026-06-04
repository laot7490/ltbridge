local SendNUIMessage = SendNUIMessage
--- Sends a message to the NUI.
---
--- **Lua Example:**
--- ```lua
--- LT.NUI.Message('open_shop', { items = {1, 2, 3} })
--- ```
---
--- **NUI (JS) Example:**
--- ```javascript
--- window.addEventListener('message', (event) => {
---     if (event.data.action === 'open_shop') {
---         console.log('Shop items:', event.data.items);
---     }
--- });
--- ```
--- @param action string Action name
--- @param data? table Optional data payload
--- @ltbridge export: Message
function MessageNUI(action, data)
    if action == nil then return printf('error', 'action is required.') end
    if data ~= nil and type(data) ~= 'table' then return printf('error', 'data must be a table, got %s instead.', type(data)) end
    SendNUIMessage({
        action = action,
        data = data or nil
    })
end
