--- Request and await an animation dictionary load.
--- @param dict string Animation dictionary name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestAnimDict
function StreamRequestAnimDict(dict, timeout)
    return AwaitAssetLoad(RequestAnimDict, HasAnimDictLoaded, dict, timeout)
end
