local GetResourceState = GetResourceState
--- Returns players owned vehicles.
--- @param source number Player source
--- @return table { vehicle, plate }
function GetOwnedVehicles(source)
    if GetResourceState('oxmysql') ~= 'missing' then
        local citizenId = GetPlayerCitizenId(source)

        if ESX then
            local result = exports.oxmysql:query_async("SELECT vehicle, plate FROM owned_vehicles WHERE owner = ?", { citizenId })
            local vehicles = {}
            for i = 1, #result do
                local vehicle = result[i].vehicle
                local plate = result[i].plate
                local model = json.decode(vehicle).model
                table.insert(vehicles, { vehicle = model, plate = plate })
            end
            return vehicles
        elseif QBX or QBCore then
            local result = exports.oxmysql:query_async("SELECT vehicle, plate FROM player_vehicles WHERE citizenid = ?", { citizenId })
            local vehicles = {}
            for i = 1, #result do
                local vehicle = result[i].vehicle
                local plate = result[i].plate
                table.insert(vehicles, { vehicle = vehicle, plate = plate })
            end
            return vehicles
        end

        return {}
    else
        printf('error', 'LT.Framework.GetOwnedVehicles needs oxmysql to work.')
        return {}
    end
end
