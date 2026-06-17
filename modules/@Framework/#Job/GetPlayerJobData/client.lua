--- @diagnostic disable

local adapters = {
    ['es_extended'] = function(jobData)
        local isBoss = (jobData.grade_name == "boss")
        return {
            name = jobData.name,
            label = jobData.label,
            grade = jobData.grade,
            gradeName = jobData.grade_name,
            gradeLabel = jobData.grade_label,
            isBoss = isBoss,
            onDuty = jobData.onduty,
        }
    end,
    ['qb-core'] = function(jobData)
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
    ['qbx_core'] = function(jobData)
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
--- @return table<{name: string, label: string, grade: number, gradeName: string, gradeLabel: string, isBoss: boolean, onDuty: boolean}>|nil
function GetPlayerJobData()
    local jobData = GetPlayerData().job
    if not jobData then
        printf('error', 'job data not found')
        return nil
    end

    return adapter(jobData)
end
