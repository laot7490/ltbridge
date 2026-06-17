local adapters = {
    ['es_extended'] = function(source, player, value)
        local clamped = MathClamp(value, 0, 200000)
        local val = clamped * 2000
        TriggerClientEvent('esx_status:add', source, 'thirst', val)
        return true
    end,
    ['qb-core'] = function(source, player, value)
        local newValue = (player.PlayerData.metadata.thirst or 0) + value
        player.Functions.SetMetaData('thirst', MathClamp(newValue, 0, 100))
        return true
    end,
    ['qbx_core'] = function(source, player, value)
        local newValue = (player.PlayerData.metadata.thirst or 0) + value
        player.Functions.SetMetaData('thirst', MathClamp(newValue, 0, 100))
        return true
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Add thirst to player.
--- @param source number Player source
--- @param value number Amount to add
--- @return boolean
function AddThirst(source, value)
    if not source then
        printf('error', 'source is required')
        return false
    end

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return false
    end

    return adapter(source, player, value) or false
end
