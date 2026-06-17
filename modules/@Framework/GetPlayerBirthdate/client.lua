---@diagnostic disable
local adapters = {
    ['es_extended'] = function()
        return GetPlayerData().dateofbirth
    end,
    ['qb-core'] = function()
        return GetPlayerData().charinfo.birthdate
    end,
    ['qbx_core'] = function()
        return GetPlayerData().charinfo.birthdate
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player date of birth.
--- @return string|nil
function GetPlayerBirthdate()
    return adapter() or nil
end
