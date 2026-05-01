local function frameworkSearch(item, metadata)
    if ESX then
        if metadata then
            printf('warning', 'This framework ^1(ESX)^7 does not support item metadata, please ensure you are using a supported inventory system or that you have the correct start order.')
        end
        local item = ESX.SearchInventory(item)
        return item.count
    elseif QBX or QBCore then
        local inv = GetPlayerData().items
        local count = 0
        for _, v in pairs(inv) do
            if v.name == item and (not metadata or (v.info == metadata or v.metadata == metadata)) then
                count = count + (v.amount or v.count)
            end
        end
        return count
    end
end

local adapters = {
    ['ox_inventory'] = function(item, metadata)
        return Inventory:GetItemCount(item, metadata, false)
    end,
    ['qs-inventory'] = function(item, metadata)
        if metadata then
            printf('warning', '^1qs-inventory^7 does not support metadata searching for item counts, you will need to get the inventory and parse it manually.')
        end
        return Inventory:Search(item)
    end,
    ['qb-inventory'] = function(item, metadata)
        return frameworkSearch(item, metadata)
    end,
    ['tgiann-inventory'] = function(item, metadata)
        return Inventory:GetItemCount(item, metadata, false)
    end,
    ['origen_inventory'] = function(item, metadata)
        return Inventory:Search('count', item, metadata).count
    end,

    fallback = function(item, metadata)
        return frameworkSearch(item, metadata)
    end
}

--- Returns count of items on players inventory. If there is none returns 0.
--- @param item string Item name
--- @param metadata? any Metadata (optional)
--- @return number
--- @ltbridge export: GetItemCount
function GetItemCountClient(item, metadata)
    local name = GetInventoryResource()
    local adapter = adapters[name]
    if not adapter then adapter = adapters.fallback end
    
    return adapter(item, metadata) or 0
end