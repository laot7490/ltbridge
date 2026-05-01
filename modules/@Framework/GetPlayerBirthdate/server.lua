--- Returns player date of birth.
--- @param source number Player source
--- @return string|nil
function GetPlayerBirthdate(source)
    local player = GetPlayer(source)
    if not player then return nil end
    if ESX then
        return player.get("dateofbirth")
    elseif QBX or QBCore then
        return player.PlayerData.charinfo.birthdate
    end
    return nil
end