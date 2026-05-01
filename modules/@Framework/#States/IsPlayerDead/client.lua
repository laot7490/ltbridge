--- Returns true if the player is dead, false otherwise.
--- @return boolean
function IsPlayerDead()
    if ESX then
        return GetPlayerData().dead
    elseif QBX or QBCore then
        local playerData = GetPlayerData()
        if not playerData then return false end
        return playerData.metadata["isdead"] or playerData.metadata["inlaststand"]
    end
    return false
end