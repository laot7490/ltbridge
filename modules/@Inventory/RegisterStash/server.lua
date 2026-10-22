local adapters = {
    ['ox_inventory'] = function(id, label, slots, maxWeight, owner)
        Inventory:RegisterStash(id, label, slots, maxWeight, owner)
        return true
    end,
    ['qs-inventory'] = function(id, label, slots, maxWeight, owner)
        -- qs creates the stash on first open; keep meta for OpenInventory
        return true
    end,
    ['qb-inventory'] = function(id, label, slots, maxWeight, owner)
        Inventory:CreateInventory(id, {
            label = label,
            maxweight = maxWeight,
            slots = slots,
        })
        return true
    end,
    ['tgiann-inventory'] = function(id, label, slots, maxWeight, owner)
        Inventory:RegisterStash(id, label, slots, maxWeight, owner)
        return true
    end,
    ['origen_inventory'] = function()
        printf('warning', 'RegisterStash is not supported for origen_inventory')
        return false
    end,
    ['one_inventory'] = function(id, label, slots, maxWeight, owner)
        Inventory:RegisterStash(id, label, slots, maxWeight, owner)
        return true
    end,
}

--- Register a stash.
--- @param id string Stash id
--- @param label string Stash label
--- @param slots number Slot count
--- @param maxWeight number Max weight
--- @param owner? string|boolean|number Owner
--- @return boolean
function RegisterStash(id, label, slots, maxWeight, owner)
    if not id or not label or not slots or not maxWeight then
        printf('error', 'id, label, slots and maxWeight are required')
        return false
    end

    local name = GetInventoryResource()
    local adapter = adapters[name]
    if not adapter then
        printf('error', 'RegisterStash is not supported for inventory: %s', tostring(name))
        return false
    end

    return adapter(id, label, slots, maxWeight, owner) or false
end
