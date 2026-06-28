local adapters = {
    ['es_extended'] = function(source, player, value)
        local clamped = MathClamp(value, 0, 200000)
        local val = clamped * 2000
        TriggerClientEvent('esx_status:add', source, 'hunger', val)
        return true
    end,
    ['qb-core'] = function(source, player, value)
        local hunger = GetPlayerMetadata(source, 'hunger') or 0
        local newValue = hunger + value
        player.Functions.SetMetaData('hunger', MathClamp(newValue, 0, 100))
        return true
    end,
    ['qbx_core'] = function(source, player, value)
        local hunger = GetPlayerMetadata(source, 'hunger') or 0
        local newValue = hunger + value
        player.Functions.SetMetaData('hunger', MathClamp(newValue, 0, 100))
        return true
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Add hunger to player.
--- @param source number Player source
--- @param value number Amount to add
--- @return boolean
function AddHunger(source, value)
    if not source then
        printf('error', 'source is required')
        return false
    end

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    return adapter(source, player, value) or false
end
