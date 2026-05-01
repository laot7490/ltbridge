--- Returns true if player loaded, false otherwise.
--- @return boolean
function IsPlayerLoaded()
    if ESX then
        return ESX.IsPlayerLoaded()
    else
        return LocalPlayer.state.isLoggedIn or false
    end
end