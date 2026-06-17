local adapters = {
    ['es_extended'] = function()
        return GetPlayerData().firstName, GetPlayerData().lastName
    end,
    ['qb-core'] = function()
        return GetPlayerData().charinfo.firstname, GetPlayerData().charinfo.lastname
    end,
    ['qbx_core'] = function()
        return GetPlayerData().charinfo.firstname, GetPlayerData().charinfo.lastname
    end,
}

local adapter = adapters[GetFramework()] or function()
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player character name.
--- @param asFullName? boolean Whether to return the full name or just the first name (Default: false)
--- @return string? Firstname (or full name if `asFullName` is true)
--- @return string? Lastname (or `nil` if `asFullName` is true)
function GetPlayerName(asFullName)
    local firstname, lastname = adapter()
    if not firstname or not lastname then
        printf('error', 'Player name or last name not found.')
        return nil
    end

    if asFullName then
        return firstname .. ' ' .. lastname
    else
        return firstname, lastname
    end
end
