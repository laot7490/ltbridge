local GetActivePlayers = GetActivePlayers
local GetPlayerPed = GetPlayerPed
local GetEntityCoords = GetEntityCoords
local PlayerId = PlayerId
local PlayerPedId = PlayerPedId

--- Get all players within a radius.
--- @param coords? vector3 Coords of area (default: Player coords)
--- @param radius number
--- @return table Array of { id, ped, dist }
--- @ltbridge export: GetPlayersInArea
function GetPlayersInArea(coords, radius)
    coords = coords or GetEntityCoords(PlayerPedId())
    local players = {}
    local myId = PlayerId()

    for _, id in ipairs(GetActivePlayers()) do
        if id ~= myId then
            local ped = GetPlayerPed(id)
            local dist = #(coords - GetEntityCoords(ped))
            if dist <= radius then
                players[#players + 1] = { id = id, ped = ped, dist = dist }
            end
        end
    end

    return players
end
