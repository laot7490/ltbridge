local cache = nil

--- This will return the jobs registered in the framework in a table.
--- @return table<number, { name: string, label: string, grades: table<string, {name: string, label: string, grade: number }>}>
function GetFrameworkJobs()

    if cache then return cache end

    local jobs = {}

    if ESX then
        jobs = ESX.GetJobs()
    elseif QBCore then
        jobs = QBCore.Shared.Jobs
    elseif QBX then
        jobs = QBX:GetJobs()
    end

    for k, v in pairs(jobs) do
        jobs[k] = {
            name = v.name,
            label = v.label,
            grades = v.grades or {}
        }
    end

    cache = jobs
    return cache
end