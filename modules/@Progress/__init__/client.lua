local resourceName = nil

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['progressbar'] = {},
    ['lation_ui'] = {},
    ['wasabi_uikit'] = {},
}

--- Returns progress bar resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetProgressResource()
    return resourceName
end

--- Force set progress bar resource. 
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetProgressResource(name)
    if not name then return end
    if not list[name] then return printf('error', 'Progress resource ^3%s^7 not found.', name) end
    resourceName = name
end

local resource = DetectResource(list, 'progress')
if resource then
    SetProgressResource(resource)
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════════════════

local function convertQBtoOX(options)
    if not options then return options end
    local prop1 = options.prop or {}
    local prop2 = options.propTwo or {}
    local props = {
        {
            model = prop1.model,
            bone = prop1.bone,
            pos = prop1.coords,
            rot = prop1.rotation,
        },
        {
            model = prop2.model,
            bone = prop2.bone,
            pos = prop2.coords,
            rot = prop2.rotation,
        }
    }
    return {
        duration = options.duration,
        label = options.label,
        position = 'bottom',
        useWhileDead = options.useWhileDead,
        canCancel = options.canCancel,
        disable = {
            move = options.controlDisables.disableMovement,
            car = options.controlDisables.disableCarMovement,
            combat = options.controlDisables.disableCombat,
            mouse = options.controlDisables.disableMouse
        },
        anim = {
            dict = options.animation.animDict,
            clip = options.animation.anim,
            flag = options.animation.flags or 49,
        },
        prop = props,
    }
end

local function convertOXtoQB(options)
    if not options then return options end
    local prop1 = (type(options.prop) == 'table' and options.prop[1]) or options.prop or {}
    local prop2 = (type(options.prop) == 'table' and options.prop[2]) or {}
    return {
        name = options.label,
        duration = options.duration,
        label = options.label,
        useWhileDead = options.useWhileDead,
        canCancel = options.canCancel,
        controlDisables = {
            disableMovement = options.disable.move,
            disableCarMovement = options.disable.car,
            disableMouse = options.disable.mouse,
            disableCombat = options.disable.combat
        },
        animation = {
            animDict = options.anim.dict,
            anim = options.anim.clip,
            flags = options.anim.flag or 49
        },
        prop = {
            model = prop1.model,
            bone = prop1.bone,
            coords = prop1.pos,
            rotation = prop1.rot
        },
        propTwo = {
            model = prop2.model,
            bone = prop2.bone,
            coords = prop2.pos,
            rotation = prop2.rot
        }
    }
end

local function convertQBtoLation(options)
    if not options then return options end
    local prop1 = options.prop or {}
    local prop2 = options.propTwo or {}
    local props = {
        {
            model = prop1.model,
            bone = prop1.bone,
            pos = prop1.coords,
            rot = prop1.rotation,
        },
        {
            model = prop2.model,
            bone = prop2.bone,
            pos = prop2.coords,
            rot = prop2.rotation,
        }
    }
    return {
        duration = options.duration,
        label = options.label,
        description = options.description,
        icon = options.icon,
        iconColor = options.iconColor,
        iconAnimation = options.iconAnimation,
        useWhileDead = options.useWhileDead,
        canCancel = options.canCancel,
        disable = {
            move = options.controlDisables.disableMovement,
            car = options.controlDisables.disableCarMovement,
            combat = options.controlDisables.disableCombat,
            mouse = options.controlDisables.disableMouse
        },
        anim = {
            dict = options.animation.animDict,
            clip = options.animation.anim,
            flag = options.animation.flags or 49,
        },
        prop = props,
    }
end

local function convertOXtoLation(options)
    if not options then return options end
    local prop1 = options.prop or {}
    local prop2 = options.propTwo or {}
    return {
        duration = options.duration,
        label = options.label,
        description = options.description,
        icon = options.icon,
        iconColor = options.iconColor,
        iconAnimation = options.iconAnimation,
        useWhileDead = options.useWhileDead,
        canCancel = options.canCancel,
        disable = options.disable,
        anim = options.anim,
        prop = {
            {
                model = prop1.model,
                bone = prop1.bone,
                pos = prop1.coords,
                rot = prop1.rotation,
            },
            {
                model = prop2.model,
                bone = prop2.bone,
                pos = prop2.coords,
                rot = prop2.rotation,
            }
        },
    }
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════════════════

local adapters = {
    ['ox_lib'] = function(options, cb, isQB)
        if isQB then
            options = convertQBtoOX(options)
        end

        local style = options.style or 'bar'
        local success = style == 'circle' and exports.ox_lib:progressCircle(options) or exports.ox_lib:progressBar(options)

        if cb then cb(success) end
        return success
    end,
    ['lt-ui'] = function(options, cb, isQB)
        if isQB then
            options = convertQBtoOX(options)
        end

        local style = options.style or 'bar'
        local success = style == 'circle' and exports.ox_lib:progressCircle(options) or exports.ox_lib:progressBar(options)

        if cb then cb(success) end
        return success
    end,
    ['progressbar'] = function(options, cb, isQB)
        if not isQB then
            options = convertOXtoQB(options)
        end
        local prom = promise.new()
        exports['progressbar']:Progress(options, function(cancelled)
            if cb then cb( not cancelled) end
            prom:resolve(not cancelled)
        end)
        return Citizen.Await(prom)
    end,
    ['lation_ui'] = function(options, cb, isQB)
        if isQB then
            options = convertQBtoLation(options)
        else
            options = convertOXtoLation(options)
        end

        local success = exports.lation_ui:progressBar(options)

        if cb then cb(success) end
        return success
    end,
    ['wasabi_uikit'] = function(options, cb, isQB)
        if isQB then
            options = convertQBtoOX(options)
        end

        local style = options.style or 'bar'
        local success = style == 'circle' and exports.wasabi_uikit:ProgressBar(options, 'circle') or exports.wasabi_uikit:ProgressBar(options, 'bar')

        if cb then cb(success) end
        return success
    end,
}

--- Open progress bar.
--- @param options table Options
--- @param cb? fun(success: boolean)
--- @param isQB? boolean If options are sent in "qb-progressbar" format, set to true. If not set, it will be assumed as "ox_lib" progress bar format.
--- @return boolean success
--- @ltbridge export: Open
function OpenProgress(options, cb, isQB)
    local name = GetProgressResource()
    local adapter = name and adapters[name]
    if adapter then
        return adapter(options, cb, isQB)
    end
    return false
end