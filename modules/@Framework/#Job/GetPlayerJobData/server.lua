local adapters = {
    ['es_extended'] = function(player)
        local job = player.getJob()
        local isBoss = (job.grade_name == "boss")
        return {
            name = job.name,
            label = job.label,
            grade = job.grade,
            gradeName = job.grade_name,
            gradeLabel = job.grade_label,
            isBoss = isBoss,
            onDuty = job.onduty,
        }
    end,
    ['qb-core'] = function(player)
        local jobData = player.PlayerData.job
        return {
            name = jobData.name,
            label = jobData.label,
            grade = jobData.grade.level,
            gradeName = jobData.grade.name,
            gradeLabel = jobData.grade.name,
            isBoss = jobData.isboss,
            onDuty = jobData.onduty,
        }
    end,
    ['qbx_core'] = function(player)
        local jobData = player.PlayerData.job
        return {
            name = jobData.name,
            label = jobData.label,
            grade = jobData.grade.level,
            gradeName = jobData.grade.name,
            gradeLabel = jobData.grade.name,
            isBoss = jobData.isboss,
            onDuty = jobData.onduty,
        }
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns player job data.
--- @param source number Player source
--- @return table<{name: string, label: string, grade: number, gradeName: string, gradeLabel: string, isBoss: boolean, onDuty: boolean}>|nil
function GetPlayerJobData(source)
    if not source then
        printf('error', 'source is required')
        return nil
    end

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return nil
    end

    return adapter(player) or nil
end
