local cbEvent = ('__%s_cb_%%s'):format(LT_RESOURCE_NAME)
local registeredCallbacks = {}

--- Internal function for getting CB event formatted.
--- @ltbridge internal
function GetCbEvent()
    return cbEvent
end

--- Internal function for callback response.
--- @ltbridge internal
function CallbackResponse(success, result, ...)
    if not success then
        if result then
            printf('error', '%s', result)
        end
        return false
    end
    return result, ...
end

--- Internal function to register a callback.
--- @param name string
--- @ltbridge internal
function SetRegisteredCallback(name)
    registeredCallbacks[name] = true
end

RegisterNetEvent(LT_RESOURCE_NAME..':cb:validate', function(callbackName, key)
    if registeredCallbacks[callbackName] then return end

    if IsDuplicityVersion() then
        TriggerClientEvent(cbEvent:format(LT_RESOURCE_NAME), source, key, 'cb_invalid')
    else
        TriggerServerEvent(cbEvent:format(LT_RESOURCE_NAME), key, 'cb_invalid')
    end
end)
