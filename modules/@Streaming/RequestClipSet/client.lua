--- Request and await a clip set load.
--- @param set string Clip set name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestClipSet
function StreamRequestClipSet(set, timeout)
    return AwaitAssetLoad(RequestClipSet, HasClipSetLoaded, set, timeout)
end
