--- Returns player data in the framework default format.
--- @return table|nil PlayerData
function GetPlayerData()
    if ESX then
        return ESX.GetPlayerData()
    elseif QBX then
        return QBX:GetPlayerData()
    elseif QBCore then
        return QBCore.Functions.GetPlayerData()
    end
    return nil
end