--- Request and await an animation set load.
--- @param set string Animation set name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestAnimSet
function StreamRequestAnimSet(set, timeout)
    return AwaitAssetLoad(RequestAnimSet, HasAnimSetLoaded, set, timeout)
end
