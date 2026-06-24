--- Yields the coroutine until the condition returns a non-nil value, or the timeout is reached.
--- If timeout is reached and no value is returned, the function returns `nil`.
--- @generic T
--- @param cb fun(): T?
--- @param timeout number? Timeout in milliseconds. Default: `1000` ms, unless set to `false`.
--- @param interval number? Interval in milliseconds to check the condition. Default: `0` ms.
--- @return T
--- @ltbridge global
function WaitFor(cb, timeout, interval)
    interval = interval or 0

    local value = cb()

    if value ~= nil then return value end

    if timeout == nil or (timeout and type(timeout) ~= 'number') then timeout = 1000 end

    local start = timeout and GetGameTimer()

    while value == nil do
        Wait(interval)

        local elapsed = timeout and GetGameTimer() - start
        if elapsed and elapsed >= timeout then
            printf('error', 'WaitFor timed out (waited %.1fms)', elapsed)
            return nil
        end

        value = cb()
    end

    return value
end
