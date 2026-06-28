local adapters = {
    ['es_extended'] = function(player)
        return player.get("phone_number")
    end,
    ['qb-core'] = function(player)
        return player.PlayerData.charinfo.phone
    end,
    ['qbx_core'] = function(player)
        return player.PlayerData.charinfo.phone
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns players phone number.
--- @param source number Player source
--- @return string|nil
function GetPlayerPhoneNumber(source)
    ltassert(source, 'source is required')

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    return adapter(player)
end
