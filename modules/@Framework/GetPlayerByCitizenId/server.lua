
-- Returns player object by identifier|citizenid.
--- @param citizenid string Player identifier|citizenid
--- @return table|nil Player or nil
function GetPlayerByCitizenId(citizenid)
    if not citizenid then return end
    
    if ESX then
        return ESX.GetPlayerFromIdentifier(citizenid)
    elseif QBCore then
        return QBCore.Functions.GetPlayerByCitizenId(citizenid)
    elseif QBX then
        return QBX:GetPlayerByCitizenId(citizenid)
    end

    return
end