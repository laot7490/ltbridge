--- Returns player character name.
--- @return string? Firstname
--- @return string? Lastname
function GetPlayerName()
    local playerData = GetPlayerData()
    if not playerData then return end

    local f
    local l

    if ESX then
        f = playerData.firstName
        l = playerData.lastName
    elseif QBX or QBCore then
        f = playerData.charinfo.firstname
        l = playerData.charinfo.lastname
    end

    if f and l then
        return f, l
    end
end