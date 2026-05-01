--- Get player state value.
--- ```lua
--- local isWanted = LT.State.GetPlayer(source, 'wanted')
--- ```
--- @param source number Player source
--- @param key string State key
--- @return any
--- @ltbridge export: GetPlayer
function GetPlayerState(source, key)
    return Player(source).state[key]
end
