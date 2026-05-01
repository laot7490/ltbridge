--- Returns all connected players.
--- @return table
function GetPlayers()
    if ESX then
        local players = ESX.GetExtendedPlayers()
        local playerList = {}
        for _, xPlayer in pairs(players) do
            table.insert(playerList, xPlayer.source)
        end
        return playerList
    elseif QBCore then
        local players = QBCore.Functions.GetPlayers()
        local playerList = {}
        for _, src in pairs(players) do
            table.insert(playerList, src)
        end
        return playerList
    elseif QBX then
        local players = QBX:GetQBPlayers()
        local playerList = {}
        for src, _ in pairs(players) do
            table.insert(playerList, src)
        end
        return playerList
    end

    return {}
end