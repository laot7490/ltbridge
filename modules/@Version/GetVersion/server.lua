--- Returns the specific resources version.
--- @param resourceName? string Defaults to current resource name.
--- @return string?
--- @ltbridge export: Get
function GetVersion(resourceName)
    local res = resourceName or __LT_RESOURCE_NAME
    if GetResourceState(res) == 'missing' then return end
    return GetResourceMetadata(res, 'version', 0)
end