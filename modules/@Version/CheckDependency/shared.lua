local function parseVersion(versionString)
    if not versionString then return nil end
    
    local parts = {}
    for num in string.gmatch(versionString, "(%d+)") do
        table.insert(parts, tonumber(num))
    end
    
    return {
        major = parts[1] or 0,
        minor = parts[2] or 0,
        patch = parts[3] or 0
    }
end

--- Compares two version strings
--- Returns: 1 if v1 > v2, -1 if v1 < v2, 0 if equals
local function compareVersions(v1, v2)
    local ver1 = parseVersion(v1)
    local ver2 = parseVersion(v2)
    
    if not ver1 or not ver2 then return 0 end
    
    if ver1.major > ver2.major then return 1 end
    if ver1.major < ver2.major then return -1 end
    
    if ver1.minor > ver2.minor then return 1 end
    if ver1.minor < ver2.minor then return -1 end
    
    if ver1.patch > ver2.patch then return 1 end
    if ver1.patch < ver2.patch then return -1 end
    
    return 0
end

--- Check if a resource dependency is met.
--- ```lua
--- if not LT.Version.CheckDependency('resourceName', '1.0.0') then
---     error()
--- end
--- ```
--- @param resourceName string Resource to check
--- @param minVersion string Minimum required version (e.g. "1.0.0")
--- @return boolean
function CheckDependency(resourceName, minVersion)
    if not resourceName or not minVersion then return false end

    local isStarted = GetResourceState(resourceName) ~= 'missing'
    if not isStarted then return false end

    local currentVersion = GetResourceMetadata(resourceName, 'version', 0)
    if not currentVersion then return false end

    local comparison = compareVersions(currentVersion, minVersion)
    if comparison < 0 then
        printf('error', 'Dependency failed: ^3\'%s\'^7 ^1v%s^7 < ^2%s^7 (required)', resourceName, currentVersion, minVersion)
        return false
    end

    return true
end