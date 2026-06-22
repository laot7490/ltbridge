local adapters = {
    ['ox_inventory'] = function(source)
        return Inventory:GetInventoryItems(source, false)
    end,
    ['qs-inventory'] = function(source)
        local playerItems = Inventory:GetInventory(source)
        local repackedTable = {}
        for _, v in pairs(playerItems) do
            table.insert(repackedTable, {
                name = v.name,
                count = v.amount or v.count,
                metadata = v.info or v.metadata or {},
                slot = v.slot,
            })
        end
        return repackedTable
    end,
    ['qb-inventory'] = function(source)
        local player = GetPlayer(source)
        if not player then return {} end
        local inventory = player.PlayerData.item
        local repackedTable = {}
        for _, v in pairs(inventory) do
            table.insert(repackedTable, {
                name = v.name,
                count = v.amount or v.count,
                metadata = v.info,
                slot = v.slot,
            })
        end
        return repackedTable
    end,
    ['tgiann-inventory'] = function(source)
        local inventory = Inventory:GetPlayerItems(source)
        local items = {}
        for _, v in pairs(inventory) do
            if tonumber(_) then
                table.insert(items,
                    { name = v.name, label = v.name, weight = 0, description = v.description, slot = v.slot, count = v.amount, metadata = v.info })
            end
        end
        return items
    end,
    ['origen_inventory'] = function(source)
        local playerInv = Inventory:GetInventory(source)
        local inv = playerInv.inventory or {}
        local repack = {}
        for _, v in pairs(inv) do
            if v.slot then
                table.insert(repack, {
                    name = v.name,
                    count = v.amount or v.count,
                    metadata = v.metadata or v.info or {},
                    slot = v.slot,
                    label = v.label or "Unknown"
                })
            end
        end
        return repack
    end,
    ['one_inventory'] = function(source)
        return Inventory:GetInventoryItems(source)
    end,

    fallback = function(source)
        if ESX then
            local Player = GetPlayer(source)
            if not Player then return {} end
            local inv = Player.getInventory()
            local repackedTable = {}
            for _, v in pairs(inv) do
                if v.count > 0 then
                    table.insert(repackedTable, {
                        name = v.name,
                        count = v.count,
                        metadata = {}, -- no support for metadata
                        slot = 0,      -- no slots
                    })
                end
            end
            return repackedTable
        elseif QBCore then
            local Player = GetPlayer(source)
            if not Player then return {} end
            local inv = Player.PlayerData.items
            local repackedTable = {}
            for _, v in pairs(inv) do
                table.insert(repackedTable, {
                    name = v.name,
                    count = v.amount or v.count,
                    metadata = v.info,
                    slot = v.slot,
                })
            end
            return repackedTable
        elseif QBX then
            local Player = GetPlayer(source)
            if not Player then return {} end
            local inventory = Player.PlayerData.items
            local repackedTable = {}
            for _, v in pairs(inventory) do
                table.insert(repackedTable, {
                    name = v.name,
                    count = v.amount,
                    metadata = v.metadata,
                    slot = v.slot,
                })
            end
            return repackedTable
        end
    end
}

--- Returns player inventory as table.
--- @param source number Player source
--- @return table {name,label?,weight?,description?,count,slot,metadata}
function GetPlayerInventory(source)
    local name = GetInventoryResource()

    local adapter = adapters[name]
    if not adapter then adapter = adapters.fallback end

    return adapter(source)
end
