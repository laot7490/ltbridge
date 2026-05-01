--- Returns player date of birth.
--- @return string|nil
function GetPlayerBirthdate()
    local data = GetPlayerData()
    if not data then return end
    if ESX then
        return data.dateofbirth
    elseif QBX or QBCore then
        return data.charinfo.birthdate
    end
    return nil
end