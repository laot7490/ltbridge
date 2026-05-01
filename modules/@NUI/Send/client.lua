local SendNUIMessage = SendNUIMessage
--- Sends a message to the NUI.
---
--- **Lua Example:**
--- ```lua
--- LT.NUI.Send('open_shop', { items = {1, 2, 3} })
--- ```
---
--- **NUI (JS) Example:**
--- ```javascript
--- window.addEventListener('message', (event) => {
---     if (event.data.action === 'open_shop') {
---         console.log('Shop items:', event.data.payload.items);
---     }
--- });
--- ```
--- @param action string Action name
--- @param payload? any Optional data payload
--- @ltbridge export: Send
function SendNUI(action, payload)
    CheckNUI()
    SendNUIMessage({
        action = action,
        payload = payload
    })
end
