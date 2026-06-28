---@diagnostic disable
local adapters = {
    ['es_extended'] = function(player)
        return player.get("dateofbirth")
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.charinfo.birthdate
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.charinfo.birthdate
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player date of birth.
--- @param source number Player source
--- @return string|nil
function GetPlayerBirthdate(source)
    ltassert(source, 'source is required')

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    return adapter(player) or nil
end
