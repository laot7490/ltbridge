local resourceName = nil

local list = {
    ['qb-vehiclekeys'] = { providers = {'qbx_vehiclekeys'} },
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
    if not name then return end
    if not list[name] then return printf('error', 'Vehiclekeys resource ^3%s^7 not found.', name) end
    resourceName = name
end

local resource = DetectResource(list, 'vehiclekeys')
if resource then
    SetKeysResource(resource)
end