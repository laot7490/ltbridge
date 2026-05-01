--- Returns player source from citizen id | identifier.
---@param citizenid string Player citizen id | identifier.
---@return number|nil
function GetPlayerSourceByCitizenId(citizenid)
    local Player = GetPlayerByCitizenId(citizenid)
    if not Player then return end

    if ESX then
        return Player.source
    elseif QBX or QBCore then
        return Player.PlayerData.source
    end
end