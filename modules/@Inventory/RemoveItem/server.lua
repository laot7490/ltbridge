local function removeESXItem(source, item, count, slot, metadata)
    local msg = "ESX framework does not support %s, please ensure you are using a supported inventory system or that you have the correct start order."
    if slot then
        printf('error', msg, 'item slots')
    end
    if metadata then
        printf('error', msg, 'item metadata')
    end
    local Player = GetPlayer(source)
    if not Player then return false end
    Player.removeInventoryItem(item, count)
    return true
end

local function removeQBItem(source, item, count, slot, metadata)
    local Player = GetPlayer(source)
    if not Player then return false end
    local success = Player.Functions.RemoveItem(item, count, slot)
    if not success then return false end
    return success
end

local adapters = {
    ['ox_inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:RemoveItem(source, item, count, metadata, slot)
        return success or false
    end,
    ['qs-inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:RemoveItem(source, item, count, slot, metadata)
        return success or false
    end,
    ['qb-inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:RemoveItem(source, item, count, slot, 'lt-bridge')
        if QBCore then
            TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'remove', count)
        end
        return success or false
    end,
    ['tgiann-inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:RemoveItem(source, item, count, slot, metadata)
        return success or false
    end,
    ['origen_inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:removeItem(source, item, count, metadata, slot, false)
        return success or false
    end,
    ['one_inventory'] = function(source, item, count, slot, metadata)
        local success = Inventory:RemoveItem(source, item, count, metadata, slot)
        return success or false
    end,

    fallback = function(source, item, count, slot, metadata)
        if ESX then
            return removeESXItem(source, item, count, slot, metadata)
        elseif QBX or QBCore then
            return removeQBItem(source, item, count, slot, metadata)
        end
    end
}

--- Remove item from player.
--- @param source number Player source
--- @param item string Item name
--- @param count number Item count
--- @param slot? number Item slot (optional)
--- @param metadata? table Item metadata (optional)
--- @return boolean
function RemoveItem(source, item, count, slot, metadata)
    local name = GetInventoryResource()
    local adapter = adapters[name]
    if not adapter then adapter = adapters.fallback end

    return adapter(source, item, count, slot, metadata)
end
