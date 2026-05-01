local GetResourceState = GetResourceState
--- Helper function to detect resources.
--- @param list table { resourceName = { providers? = { 'resourceName' } } }
--- @return string?
--- @ltbridge internal
--- @ltbridge global
function DetectResource(list, name)
    local startedResources = {}

    for resourceName, data in pairs(list) do
        if GetResourceState(resourceName) ~= 'missing' then
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
                startedResources[#startedResources+1] = resourceName
            end
        end
    end

    if #startedResources == 1 then
        return startedResources[1]
    elseif #startedResources > 1 then
        printf('warning', 'Multiple %s script detected! First resource will be used. Running resources:', name)
        for i = 1, #startedResources do
            printf(nil, '%d. %s', i, startedResources[i])
        end
        return startedResources[1]
    else
        printf('error', 'No supported %s script found.', name)
    end

    return nil
end