local adapters = {
    ['es_extended'] = function(player, name, grade)
        player.setJob(name, grade, true)
    end,
    ['qb-core'] = function(player, name, grade)
        player.Functions.SetJob(name, grade)
    end,
    ['qbx_core'] = function(player, name, grade)
        player.Functions.SetJob(name, grade)
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Set player job to given job and grade.
--- @param source number Player source
--- @param name string Job name
--- @param grade number Job grade
--- @return boolean
function SetPlayerJob(source, name, grade)
    ltassert(source and source > 0, 'source is required')

    if not name or grade == nil then
        printf('error', 'name and grade are required')
        return false
    end

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    adapter(player, name, grade)
    return true
end
