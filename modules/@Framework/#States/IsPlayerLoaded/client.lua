---@diagnostic disable
local adapters = {
    ['es_extended'] = function()
        return ESX.IsPlayerLoaded()
    end,
    ['qb-core'] = function()
        return LocalPlayer.state.isLoggedIn or false
    end,
    ['qbx_core'] = function()
        return LocalPlayer.state.isLoggedIn or false
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Returns true if player loaded, false otherwise.
--- @return boolean
function IsPlayerLoaded()
    return adapter()
end
