local pendingCallbacks = {}
local cbEvent = GetCbEvent()
local pcall = pcall

RegisterNetEvent(cbEvent:format(__LT_RESOURCE_NAME), function(key, ...)
    local cb = pendingCallbacks[key]
    if not cb then return end

    pendingCallbacks[key] = nil
    cb(...)
end)

local function triggerServerCallback(event, cb, ...)
    local key

    repeat
        key = ('%s:%s'):format(event, math.random(0, 100000))
    until not pendingCallbacks[key]

    TriggerServerEvent(__LT_RESOURCE_NAME..':cb:validate', event, key)
    TriggerServerEvent(cbEvent:format(event), __LT_RESOURCE_NAME, key, ...)

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

--- Register a client-side callback that the server can invoke.
--- @param name string Callback name
--- @param cb fun(...: any): ...any
--- @ltbridge export: Register
function RegisterCallback(name, cb)
    SetRegisteredCallback(name)

    RegisterNetEvent(cbEvent:format(name), function(resource, key, ...)
        TriggerServerEvent(cbEvent:format(resource), key, CallbackResponse(pcall(cb, ...)))
    end)
end

--- Await a server callback synchronously (yields current thread).
--- ```lua
--- local money = LT.Callback.Await('getMoney', 'cash')
--- print(money)
--- ```
--- @param name string Callback name
--- @param ... any Arguments to send
--- @return any ...
--- @ltbridge export: Await
function AwaitCallback(name, ...)
    return triggerServerCallback(name, false, ...)
end

--- Trigger a server callback asynchronously (non-blocking).
--- ```lua
--- LT.Callback.Trigger('getMoney', function(money)
---     print(money)
--- end, 'cash')
--- ```
--- @param name string Callback name
--- @param cb fun(...: any)
--- @param ... any Arguments to send
--- @ltbridge export: Trigger
function TriggerAsyncCallback(name, cb, ...)
    return triggerServerCallback(name, cb, ...)
end
