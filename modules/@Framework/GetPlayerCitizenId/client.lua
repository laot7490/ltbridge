--- Returns player citizenid | identifier.
--- @return string|nil
function GetPlayerCitizenId()
    local playerData = GetPlayerData()
    if not playerData then return end
    
    if ESX then
        return playerData.identifier
    elseif QBCore or QBX then
        return playerData.citizenid
    end

    return nil
end