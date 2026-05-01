--- Set player job to given job and grade.
--- @param source number Player source
--- @param name string Job name
--- @param grade number Job grade
--- @return boolean
function SetPlayerJob(source, name, grade)
    local Player = GetPlayer(source)
    if not Player then return false end
    if ESX then
        Player.setJob(name, grade, true)
        return true
    elseif QBX or QBCore then
        Player.Functions.SetJob(name, grade)
        return true
    end
    return false
end