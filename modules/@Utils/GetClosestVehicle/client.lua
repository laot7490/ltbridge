local GetGamePool = GetGamePool
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId

--- Get the closest vehicle to given coords.
--- @param coords? vector3 Coords of area (default: Player coords)
--- @param maxDistance? number Max search radius (default: 50.0)
--- @return number? vehicle, number? distance
--- @ltbridge export: GetClosestVehicle
function GetClosestVehicle(coords, maxDistance)
    coords = coords or GetEntityCoords(PlayerPedId())
    maxDistance = maxDistance or 50.0
    local closestVeh, closestDist

    for _, veh in ipairs(GetGamePool('CVehicle')) do
        local dist = #(coords - GetEntityCoords(veh))
        if dist < maxDistance and (not closestDist or dist < closestDist) then
            closestVeh = veh
            closestDist = dist
        end
    end

    return closestVeh, closestDist
end
