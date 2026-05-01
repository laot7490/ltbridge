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
    end
}

--- Check if player can carry item.
--- @param source number Player source
--- @param item string Item name
--- @param count number Item count
--- @return boolean
function CanCarryItem(source, item, count)
    local name = GetInventoryResource()
    if not adapters[name] then return false end

    return adapters[name](source, item, count)
end