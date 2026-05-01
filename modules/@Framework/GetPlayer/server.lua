--- Returns player object of framework default.
--- @param source number Player source
--- @return table|nil
function GetPlayer(source)
    if not source then return nil end
    
    if ESX then
        return ESX.GetPlayerFromId(source)
    elseif QBX then
        return QBX:GetPlayer(source)
    elseif QBCore then
        return QBCore.Functions.GetPlayer(source)
    end
    
    return nil
end