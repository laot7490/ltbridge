local pendingCallbacks = {}
local cbEvent = GetCbEvent()
local pcall = pcall

RegisterNetEvent(cbEvent:format(__LT_RESOURCE_NAME), function(key, ...)
    local cb = pendingCallbacks[key]
    if not cb then return end

    pendingCallbacks[key] = nil
    cb(...)
end)

local function triggerClientCallback(event, playerId, cb, ...)
    local key

    repeat
        key = ('%s:%s:%s'):format(event, math.random(0, 100000), playerId)
    until not pendingCallbacks[key]

    TriggerClientEvent(__LT_RESOURCE_NAME..':cb:validate', playerId, event, key)
    TriggerClientEvent(cbEvent:format(event), playerId, __LT_RESOURCE_NAME, key, ...)

    --- @type promise | false
    local p = not cb and promise.new()

    pendingCallbacks[key] = function(response, ...)
        if response == 'cb_invalid' then
            response = ("callback '%s' does not exist"):format(event)

            if p then
                return p:reject(response)
            end

            return printf('error', '%s', response)
        end

        response = { response, ... }

        if p then
            return p:resolve(response)
        end

        if cb then
            cb(table.unpack(response))
        end
    end

    if p then
        SetTimeout(15000, function()
            if pendingCallbacks[key] then
                pendingCallbacks[key] = nil
                p:reject(("callback '%s' timed out"):format(event))
            end
        end)

        return table.unpack(Citizen.Await(p))
    end
end

--- Register a server-side callback that clients can invoke.
--- @param name string Callback name
--- @param cb fun(source: number, ...: any): ...any
--- @ltbridge export: Register
function RegisterCallback(name, cb)
    SetRegisteredCallback(name)

    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerClientEvent(cbEvent:format(resource), source, key, CallbackResponse(pcall(cb, source, ...)))
    end)
end

--- Await a client callback synchronously (yields current thread).
--- ```lua
--- local result = LT.Callback.Await(source, 'getScreenData')
--- print(result)
--- ```
--- @param playerId number Player source
--- @param name string Callback name
--- @param ... any Arguments to send
--- @return any ...
--- @ltbridge export: Await
function AwaitCallback(playerId, name, ...)
    return triggerClientCallback(name, playerId, false, ...)
end

--- Trigger a client callback asynchronously (non-blocking).
--- ```lua
--- LT.Callback.Trigger(source, 'getScreenData', function(result)
---     print(result)
--- end)
--- ```
--- @param playerId number Player source
--- @param name string Callback name
--- @param cb fun(...: any)
--- @param ... any Arguments to send
--- @ltbridge export: Trigger
function TriggerAsyncCallback(playerId, name, cb, ...)
    return triggerClientCallback(name, playerId, cb, ...)
end
