local isNUILoaded = false
local actionToSend = 'ltbridge_check_nui'

RegisterNUICallback('ltbridge:ready', function(_, cb)
    isNUILoaded = true
    if cb then cb('ok') end
end)

--- Yields the current thread until NUI signals its ready.
---
--- **Lua Example:**
--- ```lua
--- LT.NUI.Check()
--- ```
---
--- **NUI (JS) Example:**
--- ```javascript
--- window.addEventListener('message', function(event) {
---     if (event.data.action === 'ltbridge_check_nui') {
---         fetch(`https://${GetParentResourceName()}/ltbridge:ready`, { method: 'POST' });
---     }
--- });
--- ```
--- @param action? string NUI message to send (defaults to 'ltbridge_check_nui').
--- @return boolean
--- @ltbridge export: Check
function CheckNUI(action)
    if isNUILoaded then return true end

    if action then
        actionToSend = action
    end

    while not isNUILoaded do
        SendNUIMessage({
            action = actionToSend
        })
        Wait(500)
    end
    
    return true
end

--- Returns `true` if NUI is loaded, `false` otherwise.
--- @return boolean
--- @ltbridge export: IsLoaded
function IsNUILoaded()
    return isNUILoaded
end
