local adapters = {
    ['es_extended'] = function(player)
        return player.source
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.source
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.source
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player source from citizen id | identifier.
---@param citizenid string Player citizen id | identifier.
---@return number|nil
function GetPlayerSourceByCitizenId(citizenid)
    if not citizenid then
        printf('error', 'citizenid is required')
        return nil
    end

    local player = GetPlayerByCitizenId(citizenid)
    if not player then
        printf('error', 'player not found')
        return nil
    end

    return adapter(player) or nil
end
