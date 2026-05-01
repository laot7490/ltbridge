local adapters = {
    ['lb-phone'] = function(source)
        return exports["lb-phone"]:GetEquippedPhoneNumber(source)
    end,
    ['qb-phone'] = function(source)
        return GetPlayerPhoneNumber(source)
    end,
    ['okokPhone'] = function(source)
        return exports.okokPhone:getPhoneNumberFromSource(source)
    end,
    ['qs-smartphone-pro'] = function(source)
        local identifier = GetPlayerCitizenId(source)
        return exports['qs-smartphone-pro']:GetPhoneNumberFromIdentifier(identifier, false)
    end,
    ['gksphone'] = function(source)
        return exports['gksphone']:GetPhoneBySource(source)
    end,
    ['cylex_phone'] = function(source)
        local user = exports['cylex_phone']:getUserDataBySource(source)
        return user and user.phoneNumber
    end
}

--- Returns players phone number using active phone resource. Fallbacks to framework function.
--- @param source number Player source
--- @return string|nil `Phone number` if found, `nil` otherwise.
function GetNumber(source)
    if not source then return nil end
    local adapter = adapters[GetPhoneResource()]
    if adapter then
        return adapter(source) or nil
    else
        return GetPlayerPhoneNumber(source) or nil
    end
end