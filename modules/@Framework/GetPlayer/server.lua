---@diagnostic disable
local adapters = {
    ['es_extended'] = function(source)
        return ESX.GetPlayerFromId(source)
    end,
    ['qb-core'] = function(source)
        return QBCore.Functions.GetPlayer(source)
    end,
    ['qbx_core'] = function(source)
        return QBX:GetPlayer(source)
    end,
}

local adapter = adapters[GetFramework()] or function(source)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player object of framework default.
--- @param source number Player source
--- @return table|nil
function GetPlayer(source)
    ltassert(source, 'source is required')

    return adapter(source)
end
