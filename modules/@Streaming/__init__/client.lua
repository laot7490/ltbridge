local GetGameTimer = GetGameTimer
local tostring = tostring

--- @ltbridge internal
function AwaitAssetLoad(requestFn, checkFn, asset, timeout)
    if checkFn(asset) then return true end

    requestFn(asset)

    timeout = timeout or 5000
    local start = GetGameTimer()

    while not checkFn(asset) do
        if GetGameTimer() - start > timeout then
            printf('error', 'Failed to load asset "%s" (timed out after %dms)', tostring(asset), timeout)
            return false
        end
        Wait(0)
    end

    return true
end
