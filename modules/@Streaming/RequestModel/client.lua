local joaat = joaat
local tostring = tostring
local IsModelValid = IsModelValid

--- Request and await a model load.
--- ```lua
--- if LT.Streaming.RequestModel('prop_cs_cardbox_01') then
---     -- model loaded
--- end
--- ```
--- @param model string|number Model name or hash
--- @param timeout? number Timeout in ms (default: 5000)
--- @return boolean
--- @ltbridge export: RequestModel
function StreamRequestModel(model, timeout)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelValid(model) then
        printf('error', 'Invalid model: %s', tostring(model))
        return false
    end
    return AwaitAssetLoad(RequestModel, HasModelLoaded, model, timeout)
end
