local GetResourceState = GetResourceState
--- Check if a vehicle owned by player. Returns vehicle data if owned by player, false otherwise.
--- @param source number Player source
--- @param plate string Vehicle plate
--- @return table|boolean {id = id, vehicle = model, plate = plate}
function IsVehicleOwnedByPlayer(source, plate)
    if GetResourceState('oxmysql') ~= 'missing' then
        local citizenId = GetPlayerCitizenId(source)

        if ESX then
            local result = exports.oxmysql:query_async("SELECT id, vehicle, plate FROM owned_vehicles WHERE owner = ? AND plate = ?", {
                citizenId, plate
            })
            if not result[1] then return false end

            local id = result[1].id
            local vehicle = result[1].vehicle
            local model = json.decode(vehicle).model
            return { id = id, vehicle = model, plate = plate }
        elseif QBX or QBCore then
            local result = exports.oxmysql:query_async("SELECT id, vehicle, plate FROM player_vehicles WHERE citizenid = ? AND plate = ?", {
                citizenId, plate
            })
            if not result[1] then return false end

            local id = result[1].id
            local vehicle = result[1].vehicle
            return { id = id, vehicle = vehicle, plate = plate }
        end

        return false
    else
        printf('error', 'LT.Framework.IsVehicleOwnedByPlayer needs oxmysql to work.')
        return false
    end
end
