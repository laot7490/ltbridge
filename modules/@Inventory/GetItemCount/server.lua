local function getESXItemCount(source, item, metadata)
    if metadata then
        printf('warning', 'This framework ^1(ESX)^7 does not support item metadata, please ensure you are using a supported inventory system or that you have the correct start order.')
    end
    local Player = GetPlayer(source)
    if not Player then return 0 end
    return Player.getInventoryItem(item).count or 0
end

local function getQBItemCount(source, item, metadata)
    local Player = GetPlayer(source)
    if not Player then return 0 end
    local inv = Player.PlayerData.items
    local count = 0
    for _, v in pairs(inv) do
        if v.name == item and (not metadata or (v.info == metadata or v.metadata == metadata)) then
            count = count + (v.amount or v.count)
        end
    end
    return count
end

local adapters = {
    ['ox_inventory'] = function(source, item, metadata)
        return Inventory:GetItemCount(source, item, metadata, false)
    end,
    ['qs-inventory'] = function(source, item, metadata)
        if metadata then
            printf('warning', '^1qs-inventory^7 does not support metadata searching for item counts, you will need to get the inventory and parse it manually.')
        end
        return Inventory:GetItemTotalAmount(source, item)
    end,
    ['qb-inventory'] = function(source, item, metadata)
        return getQBItemCount(source, item, metadata)
    end,
    ['tgiann-inventory'] = function(source, item, metadata)
        local result = Inventory:GetItemByName(source, item, metadata)
        return result and result.amount or 0
    end,
    ['origen_inventory'] = function(source, item, metadata)
        return Inventory:getItemCount(source, item, metadata, false)
    end,

    fallback = function(source, item, metadata)
        if ESX then
            return getESXItemCount(source, item, metadata)
        elseif QBX or QBCore then
            return getQBItemCount(source, item, metadata)
        end
    end
}

--- Returns count of items on players inventory. If there is none returns 0.
--- @param source number Player source
--- @param item string Item name
--- @param metadata? any Metadata (optional)
--- @return number
--- @ltbridge export: GetItemCount
function GetItemCountServer(source, item, metadata)
    local name = GetInventoryResource()
    local adapter = adapters[name]
    if not adapter then adapter = adapters.fallback end
    
    return adapter(source, item, metadata) or 0
end