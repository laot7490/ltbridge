---@diagnostic disable
local adapters = {
    ['es_extended'] = function(name, cb)
        ESX.RegisterUsableItem(name, function(source)
            cb(source)
        end)
    end,
    ['qb-core'] = function(name, cb)
        local func = function(src, item, itemData)
            itemData = itemData or item
            itemData.metadata = itemData.metadata or itemData.info or {}
            itemData.slot = itemData.id or itemData.slot
            cb(src, itemData)
        end
        QBCore.Functions.CreateUseableItem(name, func)
    end,
    ['qbx_core'] = function(name, cb)
        local func = function(src, item, itemData)
            itemData = itemData or item
            itemData.metadata = itemData.metadata or itemData.info or {}
            itemData.slot = itemData.id or itemData.slot
            cb(src, itemData)
        end
        QBX:CreateUseableItem(name, func)
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return
end

--- Register usable item on framework default format.
--- @param name string Item name
--- @param cb fun(source: number, item?: table)
function RegisterUsableItem(name, cb)
    ltassert(name, 'name is required')
    ltassert(cb, 'cb is required')
    ltassert(type(cb) == 'function', 'cb must be a function')
    return adapter(name, cb)
end
