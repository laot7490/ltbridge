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
--- @param data? any Optional data payload
--- @ltbridge export: Message
function MessageNUI(action, data)
    if not action then return printf('error', 'Action is required.') end
    local msg = {}
    if type(data) == "table" then
        for k, v in pairs(data) do
            msg[k] = v
        end
    end
    msg.action = action
    SendNUIMessage(msg)
end
