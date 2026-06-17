---@diagnostic disable
local adapters = {
    ['es_extended'] = function(source)
        local xPlayer = GetPlayer(source)
        if not xPlayer then return false end
        local group = xPlayer.getGroup()
        if group == 'admin' or group == 'superadmin' or group == 'god' then
            return true
        end
        return false
    end,
    ['qb-core'] = function(source)
        return QBCore.Functions.HasPermission(source, 'admin') or QBCore.Functions.HasPermission(source, 'god') or
            IsPlayerAceAllowed(source, 'command')
    end,
    ['qbx_core'] = function(source)
        return IsPlayerAceAllowed(source, 'admin')
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns true if player is admin, false otherwise.
--- @param source number Player source
--- @return boolean
function IsFrameworkAdmin(source)
    if not source then
        printf('error', 'source is required')
        return false
    end

    return adapter(source)
end
