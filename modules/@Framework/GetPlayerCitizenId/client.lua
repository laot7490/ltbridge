local adapters = {
    ['es_extended'] = function()
        return GetPlayerData().identifier
    end,
    ['qb-core'] = function()
        return GetPlayerData().citizenid
    end,
    ['qbx_core'] = function()
        return GetPlayerData().citizenid
    end,
}

local adapter = adapters[GetFramework()] or function()
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player citizenid | identifier.
--- @return string|nil
function GetPlayerCitizenId()
    return adapter()
end
