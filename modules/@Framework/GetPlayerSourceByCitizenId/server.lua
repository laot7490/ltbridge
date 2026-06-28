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
    ltassert(citizenid, 'citizenid is required')

    local player = GetPlayerByCitizenId(citizenid)
    ltassert(player, 'player not found')

    return adapter(player) or nil
end
