local resourceName = nil
local export = {}

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['esx_notify'] = {},
    ['okokNotify'] = {},
    ['pNotify'] = {},
    ['mythic_notify'] = {},
    ['brutal_notify'] = {},
    ['wasabi_notify'] = {},
    ['origen_notify'] = {},
    ['lation_ui'] = {},
    ['qb-notify'] = {}
}

--- Returns notify resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetNotifyResource()
    return resourceName
end

--- Force set notify resource. 
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetNotifyResource(name)
    if not name then return end
    if not list[name] then return printf('error', 'Notify resource ^3%s^7 not found.', name) end
    resourceName = name
    export = exports[name]
end

local resource = DetectResource(list, 'notify')
if resource then
    SetNotifyResource(resource)
end

local adapters = {
    ['ox_lib'] = function(title, message, length, variant)
        if variant == 'info' then variant = 'inform' end
        export:notify({
            title = title,
            description = message,
            type = variant,
            duration = length,
        })
    end,
    ['lt-ui'] = function(title, message, length, variant)
        if variant == 'info' then variant = 'inform' end
        export:notify({
            title = title,
            description = message,
            type = variant,
            duration = length,
        })
    end,
    ['esx_notify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        TriggerEvent('esx:showNotification', message, variant, length, title, 'top-left')
    end,
    ['okokNotify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:Alert(title, message, length, variant)
    end,
    ['pNotify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:SendNotification({ title = title, text = message, type = variant, lengthout = length })
    end,
    ['mythic_notify'] = function(title, message, length, variant)
        if variant == 'info' then variant = 'inform' end
        export:Notify(variant, message, length)
    end,
    ['brutal_notify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:SendAlert(title, message, length, variant)
    end,
    ['wasabi_notify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:notify(title, message, length, variant)
    end,
    ['origen_notify'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:ShowNotification(message, variant, length)
    end,
    ['lation_ui'] = function(title, message, length, variant)
        if variant == 'inform' then variant = 'info' end
        export:notify({
            title = title,
            message = message,
            duration = length,
            type = variant
        })
    end,
    ['qb-notify'] = function(title, message, length, variant)
        if variant == 'inform' or variant == 'info' then variant = 'primary' end
        if variant == 'warning' then variant = 'warn' end
        export:Notify(message, variant, length)
    end,
}

--- Send notification to player.
--- @param title? string Title for notification.
--- @param message string Notify message.
--- @param variant? 'success'|'error'|'info'|'warning' Type of notification.
--- @param length? number Duration in milliseconds. Defaults to 3500.
--- @ltbridge export: Send
function SendNotify(title, message, variant, length)
    local name = GetNotifyResource()
    if not name then return end
    local adapter = adapters[name]
    if not adapter then return end
    adapter(title, message, (length or 3500), (variant or 'info'))
end

RegisterNetEvent(__LT_RESOURCE_NAME..':client:@Notify:Send', function(title, message, variant, length)
    SendNotify(title, message, variant, length)
end)