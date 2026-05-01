local function getStatus(source, key)
    local Player = GetPlayer(source)
    if not Player then return end
    return Player.get(key) or nil
end

--- Returns player hunger
--- @param source number Player source
--- @return number
function GetHunger(source)
    if ESX then
        local status = getStatus(source, "status")
        if not status then return 0 end
        if type(status) ~= "table" then return 0 end
        for _, entry in ipairs(status) do
            if entry.name == "hunger" then
                return math.floor((entry.percent) + 0.5) or 0
            end
        end
    elseif QBX or QBCore then
        local Player = GetPlayer(source)
        if not Player then return 0 end
        local playerData = Player.PlayerData
        local newHunger = (playerData.metadata.hunger or 0)
        return math.floor((newHunger) + 0.5) or 0
    end

    return 0
end