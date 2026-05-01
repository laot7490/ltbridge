local GetGamePool = GetGamePool
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId

--- Get the closest object to given coords.
--- @param coords? vector3 Coords of area (default: Player coords)
--- @param maxDistance? number Max search radius (default: 50.0)
--- @return number? object, number? distance
--- @ltbridge export: GetClosestObject
function GetClosestObject(coords, maxDistance)
    coords = coords or GetEntityCoords(PlayerPedId())
    maxDistance = maxDistance or 50.0
    local closestObj, closestDist

    for _, obj in ipairs(GetGamePool('CObject')) do
        local dist = #(coords - GetEntityCoords(obj))
        if dist < maxDistance and (not closestDist or dist < closestDist) then
            closestObj = obj
            closestDist = dist
        end
    end

    return closestObj, closestDist
end
