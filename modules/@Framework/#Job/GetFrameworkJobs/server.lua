--- This will return the jobs registered in the framework in a table.
--- @return table
function GetFrameworkJobs()
    if ESX then
        return ESX.GetJobs()
    elseif QBCore then
        local jobs = {}
        for k, v in pairs(QBCore.Shared.Jobs) do
            jobs[#jobs+1] = {
                name = k,
                label = v.label,
                grade = v.grades
            }
        end
        return jobs
    elseif QBX then
        return QBX:GetJobs()
    end

    return {}
end