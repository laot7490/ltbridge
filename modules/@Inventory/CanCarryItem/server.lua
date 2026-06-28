local adapters = {
    ['ox_inventory'] = function(source, item, count)
        return Inventory:CanCarryItem(source, item, count)
    end,
    ['qs-inventory'] = function(source, item, count)
        return Inventory:CanCarryItem(source, item, count)
    end,
    ['qb-inventory'] = function(source, item, count)
        return Inventory:CanAddItem(source, item, count)
    end,
    ['tgiann-inventory'] = function(source, item, count)
        return Inventory:CanCarryItem(source, item, count)
    end,
    ['origen_inventory'] = function(source, item, count)
        return Inventory:canCarryItem(source, item, count)
    end,
    ['one_inventory'] = function(source, item, count)
        return Inventory:CanCarryItem(source, item, count)
    end,
}

--- Check if player can carry item.
--- @param source number Player source
--- @param item string Item name
--- @param count? number Item count (default: 1)
--- @return boolean
function CanCarryItem(source, item, count)
    local name = GetInventoryResource()
    if not adapters[name] then
        printf('error', 'Inventory resource not found. This function will return false.')
        return false
    end

    return adapters[name](source, item, count or 1)
end
