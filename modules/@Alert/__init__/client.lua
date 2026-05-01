local resourceName = nil

local Alert = {}

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['lation_ui'] = {},
}

--- Returns alert resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetAlertResource()
    return resourceName
end

--- Force set alert resource. 
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetAlertResource(name)
    if not name then return end
    if not list[name] then return printf('error', 'Alert resource ^3%s^7 not found.', name) end
    resourceName = name
    Alert = exports[name]
end

local resource = DetectResource(list, 'alert')
if resource then
    SetAlertResource(resource)
end

local adapters = {
    ['ox_lib'] = function(data)
        local result = Alert:alertDialog(data)
        return result
    end,
    ['lt-ui'] = function(data)
        local result = Alert:alertDialog(data)
        return result
    end,
    ['lation_ui'] = function(data)
        local result = Alert:alert(data)
        return result
    end,
}

--- Send alert dialog to player.
--- @param data table { header: string, content: string, centered: boolean, size = 'xs'|'sm'|'md'|'lg'|'xl', cancel: boolean, labels: { cancel: string, confirm: string } }
--- ```lua
--- LT.Alert.Send({
---     header = 'Alert',
---     content = 'Alert',
---     centered = true,
---     size = 'md',
---     cancel = true,
---     labels = { cancel = 'Cancel', confirm = 'Confirm' }
--- })
--- ```
--- @return 'cancel'|'confirm'|nil
--- @ltbridge export: Send
function SendAlert(data)
    if not resourceName then return end
    local adapter = adapters[resourceName]
    if not adapter then return end
    return adapter(data)
end