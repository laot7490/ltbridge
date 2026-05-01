--- Returns true if player is admin, false otherwise.
--- @param source number Player source
--- @return boolean
function IsFrameworkAdmin(source)
    if ESX then
        local xPlayer = GetPlayer(source)
        if not xPlayer then return false end
        local group = xPlayer.getGroup()
        if group == 'admin' or group == 'superadmin' then return true end
        return false
    elseif QBCore then
        local isAdmin = QBCore.Functions.HasPermission(source, 'admin')
        local isGod = QBCore.Functions.HasPermission(source, 'god')
        --- @diagnostic disable-next-line
        local isAceAllowed = IsPlayerAceAllowed(source, 'command')
        return isAdmin or isGod or isAceAllowed
    elseif QBX then
        --- @diagnostic disable-next-line
        return IsPlayerAceAllowed(source, 'admin')
    end

    return false
end