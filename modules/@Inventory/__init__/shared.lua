local resourceName = nil

Inventory = {}

local list = {
    ['ox_inventory'] = { providers = { 'tgiann-inventory', 'qs-inventory', 'origen_inventory' } },
    ['qs-inventory'] = {},
    ['qb-inventory'] = { providers = { 'ox_inventory', 'origen_inventory' } },
    ['tgiann-inventory'] = {},
    ['origen_inventory'] = { providers = { 'ox_inventory' } },
    ['one_inventory'] = {},
}

--- Returns inventory resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetInventoryResource()
    return resourceName
end

--- Force set inventory resource.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetInventoryResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Inventory resource %s not found.', name)
    Inventory = exports[name]
    resourceName = name
end

local resource = DetectResource(list, 'inventory')
if resource then
    SetInventoryResource(resource)
end
