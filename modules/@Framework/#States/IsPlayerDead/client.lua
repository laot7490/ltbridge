local adapters = {
    ['es_extended'] = function()
        return GetPlayerData().dead
    end,
    ['qb-core'] = function()
        return GetPlayerData().metadata["isdead"] or GetPlayerData().metadata["inlaststand"]
    end,
    ['qbx_core'] = function()
        return GetPlayerData().metadata["isdead"] or GetPlayerData().metadata["inlaststand"]
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Returns true if the player is dead, false otherwise.
--- @return boolean
function IsPlayerDead()
    return adapter()
end
