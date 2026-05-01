
--- Returns player job data.
--- @param source number Player source
--- @return table|nil {name,label,grade,gradeName,gradeLabel,isBoss,onDuty}
function GetPlayerJobData(source)
    if not source then return end

    local Player = GetPlayer(source)
    if not Player then return end
    
    if ESX then
        local job = Player.getJob()
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
    elseif QBCore or QBX then
        local jobData = Player.PlayerData.job
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