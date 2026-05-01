local adapters = {
    ['qb-vehiclekeys'] = function(vehicle, plate)
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)
    end,
    ['qbx_vehiclekeys'] = function(vehicle, plate)
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)
    end,
    ['qs-vehiclekeys'] = function(vehicle, plate)
        local model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        exports['qs-vehiclekeys']:RemoveKeys(plate, model)
    end,
    ['mk_vehiclekeys'] = function(vehicle, plate)
        exports["mk_vehiclekeys"]:RemoveKey(vehicle)
    end,
    ['0r-vehiclekeys'] = function(vehicle, plate)
        exports['0r-vehiclekeys']:RemoveKeys(plate)
    end,
    ['MrNewbVehicleKeys'] = function(vehicle, plate)
        exports.MrNewbVehicleKeys:RemoveKeysByPlate(plate)
    end,
    ['t1ger_keys'] = function(vehicle, plate)
        printf('error', '^4t1ger_keys^7 does not support removing keys.')
    end,
    ['mVehicle'] = function(vehicle, plate)
        printf('error', '^4mVehicle^7 does not support removing keys.')
    end,
    ['okokGarage'] = function(vehicle, plate)
        local src = GetPlayerServerId(PlayerId())
        TriggerServerEvent("okokGarage:RemoveKeys", plate, src)
    end
}

--- Remove specified vehicle keys from player(self).
--- @param vehicle number Vehicle entity.
--- @param plate? string Plate of vehicle
--- @return boolean
--- @ltbridge export: Remove
function RemoveKeys(vehicle, plate)
    local name = GetKeysResource()
    if not name then return false end
    if not vehicle or not DoesEntityExist(vehicle) then return false end

    if not plate then
        plate = GetVehicleNumberPlateText(vehicle)
    end
    
    local adapter = adapters[name]
    if not adapter then return false end

    adapter(vehicle, plate)
    return true
end