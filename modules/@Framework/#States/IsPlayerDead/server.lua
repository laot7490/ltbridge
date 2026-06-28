local adapters = {
    ['es_extended'] = function(player)
        return player.get("is_dead") or false
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.metadata.isdead or player.PlayerData.metadata.inlaststand or false
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.metadata.isdead or player.PlayerData.metadata.inlaststand or false
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Returns true if the player is dead, false otherwise.
--- @param source number Player source
--- @return boolean
function IsPlayerDead(source)
    if not source then
        printf('error', 'source is required')
        return false
    end

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    return adapter(player) or false
end
