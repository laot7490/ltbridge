--- Returns players phone number.
---@param source number Player source
---@return string|nil
function GetPlayerPhoneNumber(source)
    local Player = GetPlayer(source)
    if not Player then return end

    if ESX then
        return Player.get("phone_number")
    elseif QBX or QBCore then
        return Player.PlayerData.charinfo.phone
    end

    return nil
end