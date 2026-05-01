--- Set local player state value.
--- ```lua
--- LT.State.SetPlayer('busy', true)
--- ```
--- @param key string State key
--- @param value any State value
--- @param replicated? boolean Replicate to server (default: true)
--- @ltbridge export: SetPlayer
function SetPlayerState(key, value, replicated)
    LocalPlayer.state:set(key, value, replicated ~= false)
end
