--- Returns player metadata of the given key.
--- @param key string Metadata key
--- @return any
function GetPlayerMetadata(key)
    return GetPlayerData().metadata[key]
end