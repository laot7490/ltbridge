local adapters = {
    ['es_extended'] = function(player)
        return player.variables.firstName, player.variables.lastName
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- @param source number Player source
--- @param asFullName? boolean Whether to return the full name or just the first name (Default: false)
--- @return string? Firstname (or full name if `asFullName` is true)
--- @return string? Lastname (or `nil` if `asFullName` is true)
function GetPlayerName(source, asFullName)
    ltassert(source, 'source is required')

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    local firstname, lastname = adapter(player)
    ltassert(firstname, 'player name not found')
    ltassert(lastname, 'player last name not found')

    if asFullName then
        return firstname .. ' ' .. lastname
    else
        return firstname, lastname
    end
end
