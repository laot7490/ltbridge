local resourceName = nil

local list = {
    ['ox_fuel'] = {},
    ['lt-fuel'] = {},
    ['LegacyFuel'] = { providers = { 'lt-fuel', 'qb-fuel' } },
    ['qb-fuel'] = {},
    ['qs-fuelstations'] = {},
    ['cdn-fuel'] = {},
    ['x-fuel'] = {},
    ['okokGasStation'] = {},
    ['esx-sna-fuel'] = {},
    ['ps-fuel'] = {},
    ['BigDaddy-Fuel'] = {},
    ['Renewed-Fuel'] = {},
    ['lc_fuel'] = {}
}

--- Returns fuel resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetFuelResource()
    return resourceName
end

--- Force set fuel resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetFuelResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Fuel resource %s not found.', name)
    Fuel = exports[name]
    resourceName = name
end

local resource = DetectResource(list, 'fuel')
if resource then
    SetFuelResource(resource)
end
