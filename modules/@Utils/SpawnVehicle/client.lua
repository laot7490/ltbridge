local NetworkGetEntityIsNetworked = NetworkGetEntityIsNetworked
local NetworkRegisterEntityAsNetworked = NetworkRegisterEntityAsNetworked
local VehToNet = VehToNet
local CreateVehicle = CreateVehicle
local DoesEntityExist = DoesEntityExist
local NetworkDoesNetworkIdExist = NetworkDoesNetworkIdExist

--- Spawns a networked vehicle at the given position.
--- @param model string Model name
--- @param coords vector3 Coordinates
--- @param heading number? Heading. Default: `0.0`
--- @return boolean success
--- @return number|nil entity
--- @return number|nil netId
function SpawnVehicle(model, coords, heading)
    if not model then
        printf('error', 'model is required')
        return false
    end

    if not coords then
        printf('error', 'coords are required')
        return false
    end

    local loaded = StreamRequestModel(model)
    if not loaded then
        printf('error', 'failed to load model %s', model)
        return false
    end

    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, heading or 0.0, true, true)
    local result = WaitFor(function()
        if vehicle and DoesEntityExist(vehicle) then
            return true
        end
    end)
    if not result then
        printf('error', 'failed to spawn vehicle %s', model)
        return false
    end

    local vehNetId = WaitFor(function()
        if not NetworkGetEntityIsNetworked(vehicle) then
            NetworkRegisterEntityAsNetworked(vehicle)
        else
            local netId = VehToNet(vehicle)
            if NetworkDoesNetworkIdExist(netId) then
                return netId
            end
        end
    end)
    if not vehNetId then
        printf('error', 'failed to get vehicle netid %s', model)
        return false
    end

    return true, vehicle, vehNetId
end
