local resourceName = nil

local list = {
    ['qb-vehiclekeys'] = { providers = { 'qbx_vehiclekeys' } },
    ['qbx_vehiclekeys'] = {},
    ['qs-vehiclekeys'] = {},
    ['mk_vehiclekeys'] = {},
    ['0r-vehiclekeys'] = {},
    ['MrNewbVehicleKeys'] = {},
    ['t1ger_keys'] = {},
    ['mVehicle'] = {},
    ['okokGarage'] = {}
}

--- Returns vehicle key resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetKeysResource()
    return resourceName
end

--- Force set vehicle key resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetKeysResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Vehiclekeys resource %s not found.', name)
    resourceName = name
end

local resource = DetectResource(list, 'vehiclekeys')
if resource then
    SetKeysResource(resource)
end
