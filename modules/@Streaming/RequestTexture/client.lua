--- Request and await a texture dictionary load.
--- @param dict string Texture dictionary name
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestTexture
function StreamRequestTexture(dict, timeout)
    return AwaitAssetLoad(RequestStreamedTextureDict, HasStreamedTextureDictLoaded, dict, timeout)
end
