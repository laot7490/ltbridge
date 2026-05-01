--- Add thirst to player.
--- @param source number Player source
--- @param value number Amount to add
--- @return number? `new thirst` if success, `nil` if player not found
function AddThirst(source, value)
    local Player = GetPlayer(source)
    if not Player then return end
    if ESX then
        local clamped = math.clamp(value, 0, 200000)
        local val = clamped * 2000
        TriggerClientEvent('esx_status:add', source, 'thirst', val)
        return val
    elseif QBX or QBCore then
        local playerData = Player.PlayerData
        local new = (playerData.metadata.thirst or 0) + value
        Player.Functions.SetMetaData('thirst', math.clamp(new, 0, 100))
        return new
    end
end