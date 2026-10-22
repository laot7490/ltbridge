local GetResourceState = GetResourceState
--- Helper function to detect resources.
--- @param list table { resourceName = { providers? = { 'resourceName' } } }
--- @return string?
--- @ltbridge internal
--- @ltbridge global
function DetectResource(list, name)
    local startedResources = {}
    local presentResources = {}

    for resourceName, data in pairs(list) do
        local state = GetResourceState(resourceName)
        if state ~= 'missing' then
            local canSelect = true

            if data.providers then
                for i = 1, #data.providers do
                    if GetResourceState(data.providers[i]) ~= 'missing' then
                        canSelect = false
                        break
                    end
                end
            end

            if canSelect then
                presentResources[#presentResources + 1] = resourceName
                if state == 'started' then
                    startedResources[#startedResources + 1] = resourceName
                end
            end
        end
    end

    local candidates = startedResources
    if #candidates == 0 and #presentResources > 0 then
        candidates = presentResources
        printf('warning', 'No started %s resource found, falling back to present resource.', name)
    end

    if #candidates == 0 then
        printf('error', 'No supported %s resource found. This can cause issues with the resource.', name)
        return nil
    end

    table.sort(candidates)

    if #candidates > 1 then
        printf('warning', 'Multiple %s resources detected! First resource will be used. Running resources:', name)
        for i = 1, #candidates do
            printf(nil, '%d. %s', i, candidates[i])
        end
    end

    return candidates[1]
end
