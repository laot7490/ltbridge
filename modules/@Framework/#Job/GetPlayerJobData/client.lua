--- Returns player job data.
--- @return table|nil {name,label,grade,gradeName,gradeLabel,isBoss,onDuty}
function GetPlayerJobData()
    local jobData = GetPlayerData().job
    if ESX then
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
    elseif QBCore then
        return {
            name = jobData.name,
            label = jobData.label,
            grade = jobData.grade.level,
            gradeName = jobData.grade.name,
            gradeLabel = jobData.grade.name,
            isBoss = jobData.isboss,
            onDuty = jobData.onduty,
        }
    elseif QBX then
        return {
            name = jobData.name,
            label = jobData.label,
            grade = jobData.grade.level,
            gradeName = jobData.grade.name,
            gradeLabel = jobData.grade.name,
            isBoss = jobData.isboss,
            onDuty = jobData.onduty,
        }
    end

    return
end