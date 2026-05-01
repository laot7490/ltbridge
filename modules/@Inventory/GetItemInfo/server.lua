local adapters = {
    ['ox_inventory'] = function(item)
        local itemData = Inventory:Items(item)
        if not itemData then return {} end
        return {
            name = itemData.name or "Missing Name",
            label = itemData.label or "Missing Label",
            stack = itemData.stack or "true",
            weight = itemData.weight or 0,
            description = itemData.description or "none",
            image = GetItemImage(item),
        }
    end,
    ['qs-inventory'] = function(item)
        local itemsData = Inventory:GetItemList()
        if not itemsData then return {} end
        local itemData = itemsData[item]
        if not itemData then return {} end
        return {
            name = itemData.name or "Missing Name",
            label = itemData.label or "Missing Label",
            stack = itemData.unique or false,
            weight = itemData.weight or 0,
            description = itemData.description or "none",
            image = GetItemImage(item),
        }
    end,
    ['qb-inventory'] = function(item)
        if not QBCore then return {} end
        local itemData = QBCore.Shared.Items[item]
        if not itemData then return {} end
        return {
            name = itemData.name,
            label = itemData.label,
            stack = itemData.unique,
            weight = itemData.weight,
            description = itemData.description,
            image = GetItemImage(item)
        }
    end,
    ['tgiann-inventory'] = function(item)
        local itemData = Inventory:GetItemList()
        if not itemData[item] then return {} end
        return {
            name = itemData.name or "Missing Name",
            label = itemData.label or "Missing Label",
            stack = itemData.unique or false,
            weight = itemData.weight or 0,
            description = itemData.description or "none",
            image = GetItemImage(item),
        }
    end,
    ['origen_inventory'] = function(item)
        local itemData = Inventory:Items(item)
        if not itemData then return {} end
        return {
            name = itemData.name or "Missing Name",
            label = itemData.label or "Missing Label",
            stack = itemData.unique or false,
            weight = itemData.weight or 0,
            description = itemData.description or "none",
            image = GetItemImage(item),
        }
    end
}

--- Returns item info as a table.
--- @param item string Item name
--- @return table|nil {name, label, stack, weight, description, image}
function GetItemInfo(item)
    local name = GetInventoryResource()
    if not adapters[name] then return end
    
    return adapters[name](item)
end