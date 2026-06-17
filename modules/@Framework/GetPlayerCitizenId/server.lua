local adapters = {
    ['es_extended'] = function(player)
        return player.identifier
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.citizenid
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.citizenid
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player citizenid | identifier from source.
--- @param source number Player source
--- @return string|nil
function GetPlayerCitizenId(source)
    if not source then
        printf('error', 'source is required')
        return nil
    end

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return nil
    end

    return adapter(player)
end
