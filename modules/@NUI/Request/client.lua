local requestId = 0
local requests = {}

RegisterNUICallback('ltbridge:response', function(data, cb)
    local id = data.requestId
    if id and requests[id] then
        requests[id]:resolve(data.data)
        requests[id] = nil
    end
    if cb then cb('ok') end
end)

--- Sends a message to the NUI and waits for a response.
---
--- **Lua Example:**
--- ```lua
--- local name = LT.NUI.Request('get_name', { title = 'Enter' }, 5000)
--- print(name)
--- ```
---
--- **NUI (JS) Example:**
--- ```javascript
--- window.addEventListener('message', (event) => {
---     if (event.data.action === 'get_name') {
---         fetch(`https://${GetParentResourceName()}/ltbridge:response`, {
---             method: 'POST',
---             body: JSON.stringify({ requestId: event.data.requestId, data: 'John Doe' })
---         });
---     }
--- });
--- ```
--- @param action string Action name
--- @param data? any Optional data to send
--- @param timeout? number Optional timeout in ms (default: 5000)
--- @return any? result The data returned from the NUI, or nil if timed out.
--- @ltbridge export: Request
function NUIRequest(action, data, timeout)
    CheckNUI()
    requestId = requestId + 1
    local id = requestId
    local p = promise.new()
    
    requests[id] = p
    
    SendNUIMessage({
        action = action,
        data = data,
        requestId = id
    })
    
    -- Handle timeout
    SetTimeout(timeout or 5000, function()
        if p.state == 0 then -- Not resolved
            p:resolve(nil)
        end
    end)
    
    local result = Citizen.Await(p)
    return result
end
