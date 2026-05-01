--- Get local player state value.
--- ```lua
--- local isBusy = LT.State.GetPlayer('busy')
--- ```
--- @param key string State key
--- @return any
--- @ltbridge export: GetPlayer
function GetPlayerState(key)
    return LocalPlayer.state[key]
end
