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
    if not source then
        printf('error', 'source is required')
        return nil
    end

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return nil
    end

    local firstname, lastname = adapter(player)
    if not firstname or not lastname then
        printf('error', 'player name or last name not found')
        return nil
    end

    if asFullName then
        return firstname .. ' ' .. lastname
    else
        return firstname, lastname
    end
end
