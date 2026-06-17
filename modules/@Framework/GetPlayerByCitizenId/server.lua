---@diagnostic disable
local adapters = {
    ['es_extended'] = function(citizenid)
        return ESX.GetPlayerFromIdentifier(citizenid)
    end,
    ['qb-core'] = function(citizenid)
        return QBCore.Functions.GetPlayerByCitizenId(citizenid)
    end,
    ['qbx_core'] = function(citizenid)
        return QBX:GetPlayerByCitizenId(citizenid)
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player object by identifier|citizenid.
--- @param citizenid string Player identifier|citizenid
--- @return table|nil Player or nil
function GetPlayerByCitizenId(citizenid)
    if not citizenid then
        printf('error', 'citizenid is required')
        return nil
    end

    return adapter(citizenid) or nil
end
