LT_TARGET_NAME = nil
Target = {}

local createdZones = {}

local function detectTarget()
    if GetResourceState('ox_target') == 'started' then
        LT_TARGET_NAME = 'ox_target'
    elseif GetResourceState('qb-target') == 'started' then
        LT_TARGET_NAME = 'qb-target'
    end
    Target = exports[LT_TARGET_NAME]
end

--- Returns target resource name.
--- @return 'ox_target'|'qb-target'|nil
--- @ltbridge export: GetResource
function GetTargetResource()
    return LT_TARGET_NAME
end

--- WARNING: Do not use this. This is a internal function.
--- @ltbridge internal
function AddZone(name)
    createdZones[#createdZones+1] = name
end

--- Remove a target zone.
--- @param name string
function RemoveZone(name)
    if not name then return end
    for i, zoneName in ipairs(createdZones) do
        if zoneName == name then
            if LT_TARGET_NAME == 'ox_target' then
                Target:removeZone(name)
            elseif LT_TARGET_NAME == 'qb-target' then
                Target:RemoveZone(name)
            end
            table.remove(createdZones, i)
            break
        end
    end
end

local function createUniqueId(tbl, len, pattern)
    tbl = tbl or {}
    len = len or 8

    local id = ""
    for i = 1, len do
        local char = ""
        if pattern then
            local charIndex = math.random(1, #pattern)
            char = pattern:sub(charIndex, charIndex)
        else
            char = math.random(1, 2) == 1 and string.char(math.random(65, 90)) or string.format("%d", math.random(10) - 1) -- CAP letter and number
        end
        id = id .. char
    end
    if tbl[id] then
        return createUniqueId(tbl, len, pattern)
    end
    return id
end

local InteractIds = {}
function CreateCanInteract(cb)
    if not cb then return end
    local id = createUniqueId(InteractIds)
    InteractIds[id] = {
        id = id,
        ableToInteract = -1,
        onInteract = cb
    }
    return id
end

function CanInteract(id, ...)
    local interactData = InteractIds[id]
    if not interactData then return true end
    if interactData.ableToInteract == -1 then
        local cb = interactData.onInteract
        local canInteractStatus = cb(...)
        interactData.ableToInteract = canInteractStatus and 1 or 0
        SetTimeout(1000, function()
            interactData.ableToInteract = -1
        end)
    end
    return interactData.ableToInteract > 0
end

detectTarget()

AddEventHandler('onResourceStop', function(resource)
    if resource ~= LT_RESOURCE_NAME then return end
    for _, zone in pairs(createdZones) do
        RemoveZone(zone)
    end
end)