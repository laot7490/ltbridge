--- Sets player metadata for the given key.
--- @param source number Player source
--- @param key string Metadata key
--- @param value table | string | number | boolean Value to assign
function SetPlayerMetadata(source, key, value)
    local Player = GetPlayer(source)
    if not Player then return end
    if ESX then
        Player.setMeta(key, value, nil)
    elseif QBCore then
        Player.Functions.SetMetaData(key, value)
    elseif QBX then
        Player.Functions.SetMetaData(key, value)
    end

    return true
end