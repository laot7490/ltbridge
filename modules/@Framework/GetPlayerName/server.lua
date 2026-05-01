--- Returns player character name from source.
--- @param source number Player source
--- @return string? Firstname
--- @return string? Lastname
function GetPlayerName(source)
    if not source then return end

    local Player = GetPlayer(source)
    if not Player then return end

    local f
    local l

    if ESX then
        f = Player.variables.firstName
        l = Player.variables.lastName
    elseif QBX or QBCore then
        local playerData = Player.PlayerData
        f = playerData.charinfo.firstname
        l = playerData.charinfo.lastname
    end

    if f and l then
        return f, l
    end
end