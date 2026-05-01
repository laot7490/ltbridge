local function addESXItem(source, item, count, slot, metadata)
    local msg = "This framework ^1ESX^7 does not support ^3%s^7, please ensure you are using a supported inventory system or that you have the correct start order."
    if slot then
        printf('warning', msg, 'item slots')
    end
    if metadata then
        printf('warning', msg, 'item metadata')
    end
    local Player = GetPlayer(source)
    if not Player then return false end
    Player.addInventoryItem(item, count)
    return true
end

local function addQBItem(source, item, count, slot, metadata)
    local Player = GetPlayer(source)
    if not Player then return false end
    local success = Player.Functions.AddItem(item, count, slot, metadata)
    if not success then return false end
    return success
end

local adapters = {
    ['ox_inventory'] = function(source, item, count, slot, metadata)
        if not Inventory:CanCarryItem(source, item, count, metadata) then return false end
        local success = Inventory:AddItem(source, item, count, metadata)
        return success or false
    end,
    ['qs-inventory'] = function(source, item, count, slot, metadata)
        if not Inventory:CanCarryItem(source, item, count) then return false end
        local success = Inventory:AddItem(source, item, count, slot, metadata)
        return success or false
    end,
    ['qb-inventory'] = function(source, item, count, slot, metadata)
        if not Inventory:CanAddItem(source, item, count) then return false end
        local success = Inventory:AddItem(source, item, count, slot, metadata, 'lt_bridge')
        if QBCore then
            TriggerClientEvent('qb-inventory:client:ItemBox', source, QBCore.Shared.Items[item], 'add', count)
        end
        return success or false
    end,
    ['tgiann-inventory'] = function(source, item, count, slot, metadata)
        if not Inventory:CanCarryItem(source, item, count) then return false end
        local success = Inventory:AddItem(source, item, count, slot, metadata, false)
        return success or false
    end,
    ['origen_inventory'] = function(source, item, count, slot, metadata)
        if not Inventory:canCarryItem(source, item, count) then return false end
        local success = Inventory:addItem(source, item, count, metadata, slot, false)
        return success or false
    end,

    fallback = function(source, item, count, slot, metadata)
        if ESX then
            return addESXItem(source, item, count, slot, metadata)
        elseif QBX or QBCore then
            return addQBItem(source, item, count, slot, metadata)
        end
    end
}

--- Add item to player.
--- @param source number Player source
--- @param item string Item name
--- @param count number Item count
--- @param slot? number Item slot (optional)
--- @param metadata? table Item metadata (optional)
--- @return boolean
function AddItem(source, item, count, slot, metadata)
    local name = GetInventoryResource()

    local adapter = adapters[name]
    if not adapter then adapter = adapters.fallback end

    return adapter(source, item, count, slot, metadata)
end