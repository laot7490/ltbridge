--- Returns player citizenid | identifier from source.
--- @param source number Player source
--- @return string|nil
function GetPlayerCitizenId(source)
    if not source then return end

    local Player = GetPlayer(source)
    if not Player then return end
    
    if ESX then
        return Player and Player.identifier
    elseif QBCore or QBX then
        return Player and Player.PlayerData.citizenid
    end

    return nil
end