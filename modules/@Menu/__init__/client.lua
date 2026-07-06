local resourceName = nil
local export = {}
local menus = {}

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['qb-menu'] = {},
    ['lation_ui'] = {},
    ['wasabi_uikit'] = {},
}

--- Returns menu resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetMenuResource()
    return resourceName
end

--- Force set menu resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetMenuResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Menu resource %s not found.', name)
    resourceName = name
    export = exports[name]
end

local resource = DetectResource(list, 'menu')
if resource then
    SetMenuResource(resource)
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════════════════

local function convertQBtoOX(id, menu)
    local oxMenu = {
        id = id,
        title = "",
        canClose = true,
        options = {},
    }
    for i, v in pairs(menu) do
        if v.isMenuHeader then
            if oxMenu.title == "" then
                oxMenu.title = v.header
            end
        else
            local option = {
                title = v.header,
                description = v.txt,
                icon = v.icon,
                args = v.params.args,
                onSelect = v.action or function(selected, secondary, args)
                    local params = menu[id] and menu[id].options and menu[id].options[selected] and menu[id].options[selected].params
                    if not params then return end
                    local event = params.event
                    local isServer = params.isServer
                    if not event then return end
                    if isServer then
                        return TriggerServerEvent(event, args)
                    end
                    return TriggerEvent(event, args)
                end

            }
            table.insert(oxMenu.options, option)
        end
    end
    return oxMenu
end

local function convertOXtoQB(id, menu)
    local qbMenu = {
        {
            header = menu.title,
            isMenuHeader = true,
        }
    }
    for i, v in pairs(menu.options) do
        local button = {
            header = v.title,
            txt = v.description,
            icon = v.icon,
            disabled = v.disabled,
        }

        if v.onSelect then
            button.params = {
                event = __LT_RESOURCE_NAME .. ":client:@Menu:Callback",
                args = { id = id, selected = i, args = v.args, onSelect = v.onSelect },
            }
        else
            button.params = {} -- should fix nil errors when no onSelect is provided
        end

        table.insert(qbMenu, button)
    end

    return qbMenu
end

local function convertQBtoLation(id, menu)
    local lationMenu = {
        id = id,
        title = "",
        canClose = true,
        options = {},
    }
    for i, v in pairs(menu) do
        if v.isMenuHeader then
            if lationMenu.title == "" then
                lationMenu.title = v.header
            end
        else
            local option = {
                title = v.header,
                description = v.txt,
                icon = v.icon,
                args = v.params.args,
                onSelect = function(selected, secondary, args)
                    local params = menu[id] and menu[id].options and menu[id].options[selected] and menu[id].options[selected].params
                    if not params then return end
                    local event = params.event
                    local isServer = params.isServer
                    if not event then return end
                    if isServer then
                        return TriggerServerEvent(event, args)
                    end
                    return TriggerEvent(event, args)
                end

            }
            table.insert(lationMenu.options, option)
        end
    end
    return lationMenu
end

local function runCheckForImageIcon(icon)
    local iconStr = tostring(icon):lower()
    if iconStr:match("^https?://") or iconStr:match("^nui://") or iconStr:match("^file://") then
        return true
    end

    local extensions = { ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".svg", ".webp", ".ico" }
    for _, ext in pairs(extensions) do
        if iconStr:match(ext .. "$") then
            return true
        end
    end

    return false
end

local function convertOXtoLation(data)
    local repack = {
        id = data.id,
        title = data.title or "",
        canClose = data.canClose ~= false,
        options = {}
    }
    for k, v in pairs(data.options) do
        if v.iconColor then
            if v.icon and runCheckForImageIcon(v.icon) then
                v.iconColor = nil
            end
        end
        table.insert(repack.options, v)
    end

    return repack
end

local function convertQBtoWasabi(id, menu)
    local wasabiMenu = {
        id = id,
        title = "",
        canClose = true,
        options = {},
    }
    for i, v in pairs(menu) do
        if v.isMenuHeader then
            if wasabiMenu.title == "" then
                wasabiMenu.title = v.header
            end
        else
            local option = {
                title = v.header,
                description = v.txt,
                icon = v.icon,
                args = v.params.args,
                onSelect = v.action or function(selected, secondary, args)
                    local params = menu[id] and menu[id].options and menu[id].options[selected] and menu[id].options[selected].params
                    if not params then return end
                    local event = params.event
                    local isServer = params.isServer
                    if not event then return end
                    if isServer then
                        return TriggerServerEvent(event, args)
                    end
                    return TriggerEvent(event, args)
                end

            }
            table.insert(wasabiMenu.options, option)
        end
    end
    return wasabiMenu
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════════════════

local adapters = {
    ['ox_lib'] = function(id, data, isQB)
        if isQB then
            data = convertQBtoOX(id, data)
        end
        export:registerContext(data)
        export:showContext(id)
        return data
    end,
    ['lt-ui'] = function(id, data, isQB)
        if isQB then
            data = convertQBtoOX(id, data)
        end
        export:registerContext(data)
        export:showContext(id)
        return data
    end,
    ['qb-menu'] = function(id, data, isQB)
        if not isQB then
            data = convertOXtoQB(id, data)
        end
        export:openMenu(data)
        return data
    end,
    ['lation_ui'] = function(id, data, isQB)
        if isQB then
            data = convertQBtoLation(id, data)
        else
            data = convertOXtoLation(data)
        end
        export:registerMenu(data)
        export:showMenu(id)
        return data
    end,
    ['wasabi_uikit'] = function(id, data, isQB)
        if isQB then
            data = convertQBtoWasabi(id, data)
        end
        export:RegisterContextMenu(data)
        export:OpenContextMenu(id)
        return data
    end,
}

--- Opens a interactable menu.
--- @param id string Menu unique ID
--- @param data table Menu data
--- @param isQB? boolean If data table is sent with QB format set to true, default: false
--- @return table|nil
--- @ltbridge export: Open
function OpenMenu(id, data, isQB)
    local resource = GetMenuResource()
    ltassert(resource, 'menu resource not found.')
    local adapter = adapters[resource]
    data.id = id
    menus[id] = adapter(id, data, isQB)
    return menus[id]
end

--- Event to handle callback from menu selection.
--- @param _args table The arguments passed to the callback.
--- @return nil
RegisterNetEvent(__LT_RESOURCE_NAME .. ":client:@Menu:Callback", function(_args)
    local id = _args.id
    local onSelect = _args.onSelect
    local args = _args.args
    menus[id] = nil
    onSelect(args)
end)
