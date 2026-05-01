local adapters = {
    ['ox_inventory'] = function(source, slot)
        return Inventory:GetSlot(source, slot)
    end,
    ['qs-inventory'] = function(source, slot)
        local playerItems = Inventory:GetInventory(source)
        for _, item in pairs(playerItems) do
            if item.slot == slot then
                return {
                    name = item.name,
                    label = item.label,
                    weight = item.weight,
                    slot = slot,
                    count = item.amount or item.count,
                    metadata = item.info or item.metadata or {},
                    stack = item.unique or item.stack or false,
                    description = item.description
                }
            end
        end
        return {}
    end,
    ['qb-inventory'] = function(source, slot)
        local slotData = Inventory:GetItemBySlot(source, slot)
        if not slotData then return {} end
        return {
            name = slotData.name,
            label = slotData.name,
            weight = slotData.weight,
            slot = slotData.slot,
            count = slotData.amount,
            metadata = slotData.info,
            stack = slotData.unique,
            description = slotData.description
        }
    end,
    ['tgiann-inventory'] = function(source, slot)
        local item = Inventory:GetItemBySlot(source, slot)
        if not item then return {} end
        return {
            name = item.name,
            label = item.label,
            weight = item.weight,
            slot = slot,
            count = item.amount or item.count,
            metadata = item.info or item.metadata or {},
            stack = item.unique or item.stack or false,
            description = item.description
        }
    end,
    ['origen_inventory'] = function(source, slot)
        local playerInv = GetPlayerInventory(source)
        for _, v in pairs(playerInv) do
            if v.slot == slot then
                return {
                    name = v.name,
                    count = v.count or v.amount,
                    weight = v.weight or 0,
                    metadata = v.metadata or v.info or {},
                    slot = v.slot,
                    label = v.label
                }
            end
        end
        return {}
    end
}

--- Returns the specified slot item data as a table.
--- @param source number Player source
--- @param slot number Slot to search
--- @return table|nil {name, label, count, slot, weight, metadata, stack, description}
function GetItemBySlot(source, slot)
    local name = GetInventoryResource()
    if not adapters[name] then return nil end
    
    return adapters[name](source, slot)
end