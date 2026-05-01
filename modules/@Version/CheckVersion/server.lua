local format = string.format
local PerformHttpRequest = PerformHttpRequest
--- Checks version of resource and prints update message or up-to-date message.
--- @param data table
--- @param messages? table (Optional, set with caution) Print messages that will be displayed on console. { upToDate, updateAvailable, download }
--- ```lua
--- LT.CheckVersion({
---     -- Directly check from repo:
---     repository = 'laot7490/laot-core', -- directly check github repo for latest release
---
---     -- Or use a custom URL:
---     url = 'https://raw.githubusercontent.com/laot7490/laot-versions/refs/heads/master/check.json',
---     resourceName = 'lt-fuel', -- (optional) defaults to current resource
---     downloadUrl = 'https://portal.cfx.re/assets/granted-assets', -- (optional) download link
---
---     -- File types:
---     -- 'JSON' (default)
---     --   Expects a JSON object with multiple resources:
---     --   {
---     --     "lt-fuel": "1.0.0",
---     --     "other-resource": "2.3.1"
---     --   }
---     --   Will match using the resourceName key.
---
---     -- 'SINGLE'
---     --   Expects a plain version string response:
---     --   1.0.0
---
---     fileType = 'JSON',
--- })
--- @ltbridge export: Check
function CheckVersion(data, messages)
    local resourceName <const> = (data and data.resourceName) or LT_RESOURCE_NAME
    local currentVersion <const> = GetResourceMetadata(resourceName, 'version', 0)
    if not currentVersion then return printf('error', 'No version found for resource %s.', resourceName) end

    local upToDate <const> = (messages and messages.upToDate) or '^2[%s]^7 Up-to-date (v%s)'
    local updateMsg <const> = (messages and messages.updateAvailable) or '^3[%s]^7 Update available: ^1v%s^7 → ^2v%s^7'
    local download <const> = (messages and messages.download) or '  Download: ^4%s^7'

    local repo <const> = data and (data.repository or data.repo) or nil
    if repo ~= nil then
        local currentSemver <const> = currentVersion:match('%d+%.%d+%.%d+')
        if not currentSemver then 
            printf('error', 'Unable to determine semantic version (x.y.z) for %s. Found: %s', resourceName, currentVersion) 
            return
        end

        SetTimeout(1000, function()
            PerformHttpRequest(('https://api.github.com/repos/%s/releases/latest'):format(repo), function(status, response)
                if status ~= 200 then return end

                response = json.decode(response)
                if not response or response.prerelease or not response.tag_name then return end

                local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')
                if not latestVersion or latestVersion == currentSemver then
                    print(format(upToDate, resourceName, currentSemver))
                    return
                end

                local cv = {}
                for part in string.gmatch(currentSemver, '%d+') do table.insert(cv, tonumber(part)) end
                local lv = {}
                for part in string.gmatch(latestVersion, '%d+') do table.insert(lv, tonumber(part)) end

                local isOutdated = false
                for i = 1, math.max(#cv, #lv) do
                    local current = cv[i] or 0
                    local minimum = lv[i] or 0

                    if current ~= minimum then
                        if current < minimum then
                            isOutdated = true
                        end
                        break
                    end
                end

                if isOutdated then
                    print(format(updateMsg, resourceName, currentSemver, latestVersion))
                    print(format(download, response.html_url))
                else
                    print(format(upToDate, resourceName, currentSemver))
                end
            end, 'GET')
        end)

        return
    else
        local fileType = (data and data.fileType) or 'JSON'
        local url = (data and data.url)
        if not url then printf('error', 'No URL provided for resource version check %s.', resourceName) return end
        local downloadURL = (data and data.downloadUrl) or ''

        PerformHttpRequest(url, function(err, resultData, _)
            if err ~= 200 or not resultData then return end

            local remoteVersion

            if fileType == 'JSON' then
                local decoded = json.decode(resultData)
                if not decoded or not decoded[resourceName] then 
                    return printf('error', 'Version check for %s resource failed. No matching version was found on the source, or the source URL could not be reached.', resourceName)
                end
                remoteVersion = decoded[resourceName]

            elseif fileType == 'SINGLE' then
                remoteVersion = tostring(resultData):gsub("%s+", "")

            else
                return printf('error', 'Invalid version file type: %s', fileType)
            end

            if not remoteVersion or remoteVersion == '' then return end

            if currentVersion == remoteVersion then
                print(format(upToDate, resourceName, currentVersion))
            else
                print(format(updateMsg, resourceName, currentVersion, remoteVersion))
                print(format(download, downloadURL))
            end
        end, 'GET')
    end
end