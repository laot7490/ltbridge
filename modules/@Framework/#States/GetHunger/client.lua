local function getStatus(search)
    local playerData = GetPlayerData()
    if not playerData then return 0 end
    local status = playerData.variables.status
    for _, entry in ipairs(status) do
        if entry.name == search then
            return entry.percent or 0
        end
    end
    return 0
end

--- Returns player hunger
--- @return number
function GetHunger()
    if ESX then
        local status = getStatus("hunger")
        return math.floor((status) + 0.5) or 0
    elseif QBX or QBCore then
        local hunger = GetPlayerMetadata("hunger") or 0
        return math.floor((hunger) + 0.5) or 0
    end

    return 0
end