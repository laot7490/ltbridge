--- Returns player metadata of the given key.
--- @param source number Player source
--- @param key string Metadata key
--- @return any
function GetPlayerMetadata(source, key)
    local Player = GetPlayer(source)
    if not Player then return end
    
    if ESX then
        return Player.getMeta(key) or false
    elseif QBX or QBCore then
        local playerData = Player.PlayerData
        return playerData.metadata[key] or false
    end

    return nil
end