local resourceName = nil

Inventory = {}

local list = {
    ['ox_inventory'] = { providers = {'tgiann-inventory', 'qs-inventory', 'origen_inventory'} },
    ['qs-inventory'] = {},
    ['qb-inventory'] = { providers = {'ox_inventory','origen_inventory'} },
    ['tgiann-inventory'] = {},
    ['origen_inventory'] = { providers = {'ox_inventory'} },
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
    if not name then return end
    if not list[name] then return printf('error', 'Inventory resource ^3%s^7 not found.', name) end
    Inventory = exports[name]
    resourceName = name
end

local resource = DetectResource(list, 'inventory')
if resource then
    SetInventoryResource(resource)
end