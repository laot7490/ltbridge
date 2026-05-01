local GetGamePool = GetGamePool
local GetEntityCoords = GetEntityCoords
local PlayerPedId = PlayerPedId
local IsPedAPlayer = IsPedAPlayer
local PlayerPedId = PlayerPedId

--- Get the closest ped to given coords (excluding players).
--- @param coords? vector3 Coords of area (default: Player coords)
--- @param maxDistance? number Max search radius (default: 50.0)
--- @return number? ped, number? distance
--- @ltbridge export: GetClosestPed
function GetClosestPed(coords, maxDistance)
    coords = coords or GetEntityCoords(PlayerPedId())
    maxDistance = maxDistance or 50.0
    local closestPed, closestDist
    local myPed = PlayerPedId()

    for _, ped in ipairs(GetGamePool('CPed')) do
        if ped ~= myPed and not IsPedAPlayer(ped) then
            local dist = #(coords - GetEntityCoords(ped))
            if dist < maxDistance and (not closestDist or dist < closestDist) then
                closestPed = ped
                closestDist = dist
            end
        end
    end

    return closestPed, closestDist
end
