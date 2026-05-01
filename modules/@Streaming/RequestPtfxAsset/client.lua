--- Request and await a named PTFX asset load.
--- @param asset string PTFX asset name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestPtfxAsset
function StreamRequestPtfxAsset(asset, timeout)
    return AwaitAssetLoad(RequestNamedPtfxAsset, HasNamedPtfxAssetLoaded, asset, timeout)
end
