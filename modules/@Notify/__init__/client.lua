local resourceName = nil
local exp = {}

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
    exp = exports[name]
end

local resource = DetectResource(list, 'notify')
if resource then
    SetNotifyResource(resource)
end

local adapters = {
    ['ox_lib'] = function(title, message, time, variant)
        if variant == 'info' then variant = 'inform' end
        exp:notify({
            title = title,
            description = message,
            type = variant,
            duration = time,
        })
    end,
    ['lt-ui'] = function(title, message, time, variant)
        if variant == 'info' then variant = 'inform' end
        exp:notify({
            title = title,
            description = message,
            type = variant,
            duration = time,
        })
    end,
    ['esx_notify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        TriggerEvent('esx:showNotification', message, variant, time, title, 'top-left')
    end,
    ['okokNotify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:Alert(title, message, time, variant)
    end,
    ['pNotify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:SendNotification({ title = title, text = message, type = variant, timeout = time })
    end,
    ['mythic_notify'] = function(title, message, time, variant)
        if variant == 'info' then variant = 'inform' end
        exp:Notify(variant, message, time)
    end,
    ['brutal_notify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:SendAlert(title, message, time, variant)
    end,
    ['wasabi_notify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:notify(title, message, time, variant)
    end,
    ['origen_notify'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:ShowNotification(message, variant, time)
    end,
    ['lation_ui'] = function(title, message, time, variant)
        if variant == 'inform' then variant = 'info' end
        exp:notify({
            title = title,
            message = message,
            duration = time,
            type = variant
        })
    end,
}

--- Send notification to player.
--- @param title? string Title for notification.
--- @param message string Notify message.
--- @param variant? 'success'|'error'|'info'|'warning' Type of notification.
--- @param time? number Duration in milliseconds. Defaults to 3500.
--- @ltbridge export: Send
function SendNotify(title, message, variant, time)
    local name = GetNotifyResource()
    if not name then return end
    local adapter = adapters[name]
    if not adapter then return end
    adapter(title, message, (time or 3500), (variant or 'info'))
end

RegisterNetEvent(LT_RESOURCE_NAME..':client:@Notify:Send', function(title, message, variant, time)
    SendNotify(title, message, variant, time)
end)