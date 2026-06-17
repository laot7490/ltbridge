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
    if not source then
        printf('error', 'source is required')
        return false
    end

    if not name or not grade then
        printf('error', 'name and grade are required')
        return false
    end

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return false
    end

    adapter(player, name, grade)
    return true
end
