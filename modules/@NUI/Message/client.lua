local SendNUIMessage = SendNUIMessage

local function checkTable(tbl)
    for k, v in pairs(tbl) do
        if type(v) == "function" or type(v) == 'thread' then
            return false, ('functions and threads are not supported on NUI messages. (%s : %s)'):format(k, v)
        elseif type(v) == 'table' then
            local success, error = checkTable(v)
            if not success then return false, error end
        end
    end
    return true, nil
end

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
    local payload = {}
    if data ~= nil then
        if type(data) ~= 'table' then return printf('error', 'data must be a table, got %s instead.', type(data)) end
        local success, error = checkTable(data)
        if not success then return printf('error', '%s', error) end
        for k, v in pairs(data) do
            payload[k] = v
        end
    end
    payload.action = action
    SendNUIMessage(payload)
end
