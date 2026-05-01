local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId

--- Get the closest player to given coords.
--- ```lua
--- local playerId, ped, dist = LT.Utils.GetClosestPlayer()
--- ```
--- @param coords? vector3 Coords of area (default: Player coords)
--- @param maxDistance? number Max search radius (default: 50.0)
--- @return number? playerId, number? ped, number? distance
--- @ltbridge export: GetClosestPlayer
function GetClosestPlayer(coords, maxDistance)
    coords = coords or GetEntityCoords(PlayerPedId())
    maxDistance = maxDistance or 50.0
    local closestId, closestPed, closestDist
    local myId = PlayerId()

    for _, id in ipairs(GetActivePlayers()) do
        if id ~= myId then
            local ped = GetPlayerPed(id)
            local dist = #(coords - GetEntityCoords(ped))
            if dist < maxDistance and (not closestDist or dist < closestDist) then
                closestId = id
                closestPed = ped
                closestDist = dist
            end
        end
    end

    return closestId, closestPed, closestDist
end
