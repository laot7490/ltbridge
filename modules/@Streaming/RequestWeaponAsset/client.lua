local joaat = joaat

--- Request and await a weapon asset load.
--- @param hash number|string Weapon hash or name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestWeaponAsset
function StreamRequestWeaponAsset(hash, timeout)
    if type(hash) == 'string' then hash = joaat(hash) end
    return AwaitAssetLoad(function(h) RequestWeaponAsset(h, 31, 0) end, HasWeaponAssetLoaded, hash, timeout)
end
