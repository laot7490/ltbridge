local adapters = {
    ['qb-vehiclekeys'] = function(vehicle, plate)
        TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
    end,
    ['qbx_vehiclekeys'] = function(vehicle, plate)
        TriggerServerEvent("qb-vehiclekeys:server:AcquireVehicleKeys", plate)
    end,
    ['qs-vehiclekeys'] = function(vehicle, plate)
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
    end,
    ['mk_vehiclekeys'] = function(vehicle, plate)
        exports["mk_vehiclekeys"]:AddKey(vehicle)
    end,
    ['0r-vehiclekeys'] = function(vehicle, plate)
        exports['0r-vehiclekeys']:GiveKeys(plate)
    end,
    ['MrNewbVehicleKeys'] = function(vehicle, plate)
        exports.MrNewbVehicleKeys:GiveKeysByPlate(plate)
    end,
    ['t1ger_keys'] = function(vehicle, plate)
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['t1ger_keys']:GiveTemporaryKeys(plate, model, '')
    end,
    ['mVehicle'] = function(vehicle, plate)
        exports.mVehicle:AddTemporalVehicleClient(vehicle)
    end,
    ['okokGarage'] = function(vehicle, plate)
        TriggerServerEvent('okokGarage:GiveKeys', plate)
    end
}

--- Give player(self) the keys of specified vehicle.
--- @param vehicle number Vehicle entity.
--- @param plate? string Plate of vehicle
--- @return boolean
--- @ltbridge export: Give
function GiveKeys(vehicle, plate)
    local name = GetKeysResource()
    ltassert(name, 'vehiclekeys resource not found.')
    ltassert(vehicle and DoesEntityExist(vehicle), 'vehicle not found.')

    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end

    local adapter = adapters[name]
    adapter(vehicle, plate)
    return true
end
