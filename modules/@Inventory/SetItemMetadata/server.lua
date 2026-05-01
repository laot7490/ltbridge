local adapters = {
    ['ox_inventory'] = function(source, item, slot, metadata)
        return Inventory:SetMetadata(source, slot, metadata)
    end,
    ['qs-inventory'] = function(source, item, slot, metadata)
        return Inventory:SetItemMetadata(source, slot, metadata)
    end,
    ['qb-inventory'] = function(source, item, slot, metadata)
        local player = GetPlayer(source)
        if not player then return false end
        player.Functions.RemoveItem(item, 1, slot)
        return player.Functions.AddItem(item, 1, slot, metadata)
    end,
    ['tgiann-inventory'] = function(source, item, slot, metadata)
        return Inventory:UpdateItemMetadata(source, item, slot, metadata)
    end,
    ['origen_inventory'] = function(source, item, slot, metadata)
        return Inventory:setMetadata(source, slot, metadata)
    end
}

--- Set/change metadata of item.
--- @param source number Player source
--- @param item string Item name
--- @param slot number Item slot
--- @param metadata any New metadata
function SetItemMetadata(source, item, slot, metadata)
    local name = GetInventoryResource()
    if not adapters[name] then return 0 end
    
    return adapters[name](source, item, slot, metadata)
end