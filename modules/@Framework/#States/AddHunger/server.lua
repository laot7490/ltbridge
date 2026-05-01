--- Add hunger to player.
--- @param source number Player source
--- @param value number Amount to add
--- @return number? `new hunger` if success, `nil` if player not found
function AddHunger(source, value)
    local Player = GetPlayer(source)
    if not Player then return end
    if ESX then
        local clamped = math.clamp(value, 0, 200000)
        local val = clamped * 2000
        TriggerClientEvent('esx_status:add', source, 'hunger', val)
        return val
    elseif QBX or QBCore then
        local playerData = Player.PlayerData
        local newHunger = (playerData.metadata.hunger or 0) + value
        Player.Functions.SetMetaData('hunger', math.clamp(newHunger, 0, 100))
        return newHunger
    end
end