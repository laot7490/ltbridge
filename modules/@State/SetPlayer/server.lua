--- Set player state value.
--- ```lua
--- LT.State.SetPlayer(source, 'wanted', true)
--- ```
--- @param source number Player source
--- @param key string State key
--- @param value any State value
--- @param replicated? boolean Replicate to clients (default: true)
--- @ltbridge export: SetPlayer
function SetPlayerState(source, key, value, replicated)
    Player(source).state:set(key, value, replicated ~= false)
end
