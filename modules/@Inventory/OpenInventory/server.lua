local adapters = {
    ['ox_inventory'] = function(source, invType, data)
        Inventory:forceOpenInventory(source, invType, data)
        return true
    end,
    ['qs-inventory'] = function(source, invType, data)
        if invType == 'player' or invType == 'otherplayer' then
            local target = type(data) == 'table' and (data.id or data.source) or data
            Inventory:OpenInventoryById(source, tonumber(target))
            return true
        end
        local id = type(data) == 'table' and (data.id or data.name) or data
        if not id then return false end
        local slots = type(data) == 'table' and data.slots or 50
        local maxWeight = type(data) == 'table' and (data.maxWeight or data.maxweight) or 100000
        local label = type(data) == 'table' and data.label or tostring(id)
        Inventory:RegisterStash(source, id, slots, maxWeight, label)
        return true
    end,
    ['qb-inventory'] = function(source, invType, data)
        if invType == 'player' or invType == 'otherplayer' then
            local target = type(data) == 'table' and (data.id or data.source) or data
            Inventory:OpenInventoryById(source, tonumber(target))
            return true
        end
        local id = type(data) == 'table' and (data.id or data.name) or data
        if not id then
            Inventory:OpenInventory(source)
            return true
        end
        local extra = nil
        if type(data) == 'table' then
            extra = {
                label = data.label,
                maxweight = data.maxWeight or data.maxweight,
                slots = data.slots,
            }
        end
        Inventory:OpenInventory(source, id, extra)
        return true
    end,
    ['tgiann-inventory'] = function(source, invType, data)
        if type(data) == 'table' and (data.id or data.name) then
            local invId = data.id or data.name
            Inventory:ForceOpenInventory(source, invType, invId, data)
        else
            Inventory:ForceOpenInventory(source, invType, data)
        end
        return true
    end,
    ['origen_inventory'] = function()
        printf('warning', 'OpenInventory is not supported for origen_inventory')
        return false
    end,
    ['one_inventory'] = function(source, invType, data)
        return Inventory:OpenInventory(source, invType, data) or false
    end,
}

--- Open inventory for player.
--- @param source number Player source
--- @param invType string Inventory type
--- @param data? string|number|table Extra data (id, etc.)
--- @return boolean
function OpenInventory(source, invType, data)
    ltassert(source and source > 0, 'source is required')
    ltassert(invType, 'invType is required')

    local name = GetInventoryResource()
    local adapter = adapters[name]
    if not adapter then
        printf('error', 'OpenInventory is not supported for inventory: %s', tostring(name))
        return false
    end

    return adapter(source, invType, data) or false
end
