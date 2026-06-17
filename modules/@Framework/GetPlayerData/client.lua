---@diagnostic disable
local adapters = {
    ['es_extended'] = function()
        return ESX.GetPlayerData()
    end,
    ['qb-core'] = function()
        return QBCore.Functions.GetPlayerData()
    end,
    ['qbx_core'] = function()
        return QBX:GetPlayerData()
    end,
}

local adapter = adapters[GetFramework()] or function()
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player data in the framework default format.
--- @return table|nil PlayerData
function GetPlayerData()
    return adapter()
end
