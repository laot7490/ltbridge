local isServer <const> = IsDuplicityVersion()
local format = string.format

--- @ltbridge internal
--- @param name string
--- @param remote? boolean
--- @return string
function GetEventName(name, remote)
    local side
    if remote then
        side = isServer and 'client' or 'server'
    else
        side = isServer and 'server' or 'client'
    end

    return format('%s:%s:%s', LT_RESOURCE_NAME, side, name)
end