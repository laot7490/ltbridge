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

--- Returns player thirst
--- @return number
function GetThirst()
    if ESX then
        local status = getStatus("thirst")
        return math.floor((status) + 0.5) or 0
    elseif QBX or QBCore then
        local val = GetPlayerMetadata("thirst") or 0
        return math.floor((val) + 0.5) or 0
    end

    return 0
end