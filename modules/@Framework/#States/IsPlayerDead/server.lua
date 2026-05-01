--- Returns true if the player is dead, false otherwise.
--- @param source number Player source
--- @return boolean
function IsPlayerDead(source)
    if ESX then
        local xPlayer = GetPlayer(source)
        if not xPlayer then return false end
        return xPlayer.get("is_dead") or false
    elseif QBX or QBCore then
        local player = GetPlayer(source)
        if not player then return false end
        local playerData = player.PlayerData
        return playerData.metadata.isdead or playerData.metadata.inlaststand or false
    end
    return false
end