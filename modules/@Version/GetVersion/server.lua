--- Returns the specific resource's version.
--- @param resourceName? string Defaults to current resource name.
--- @return string?
--- @ltbridge export: Get
function GetVersion(resourceName)
    local res = resourceName or __LT_RESOURCE_NAME
    ltassert(GetResourceState(res) == 'started', 'resource %s is not started.', res)
    return GetResourceMetadata(res, 'version', 0)
end
