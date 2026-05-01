local function fixOX(options)
    for i = 1, #options do
        local opt = options[i]
        local action = opt.onSelect or opt.action
        if not action then 
            local _type = opt.type
            if _type and _type == "server" then
                opt.serverEvent = opt.event
                opt.event = nil
            end

        else
            local select = function(entityOrData)
                if type(entityOrData) == 'table' then
                    return action(entityOrData.entity)
                end
                return action(entityOrData)
            end
            opt.onSelect = select
        end
        opt.groups = opt.job or opt.groups
        local optionsCanInteract = opt.canInteract
        if optionsCanInteract then
            local id = CreateCanInteract(optionsCanInteract)
            opt.canInteract = function(...)
                return CanInteract(id, ...)
            end
        end
    end
    return options
end

local function fixQB(options)
    for i = 1, #options do
        local opt = options[i]
        local action = opt.onSelect or opt.action
        local select = action and function(entityOrData)
            if type(entityOrData) == 'table' then
                return action(entityOrData.entity)
            end
            return action(entityOrData)
        end
        if opt.serverEvent then
            opt.type = "server"
            opt.event = opt.serverEvent
        elseif opt.event then
            opt.type = "client"
            opt.event = opt.event
        end
        options[i].action = select
        options[i].job = opt.job or opt.groups
        options[i].jobType = opt.jobType
        local optionsCanInteract = opt.canInteract
        if optionsCanInteract then
            local id = CreateCanInteract(optionsCanInteract)
            opt.canInteract = function(...)
                return CanInteract(id, ...)
            end
        end
    end
    return options
end

--- Internal function to fix options for working on all target systems.
--- @param options table
--- @return table
--- @ltbridge internal
function FixOptions(options)
    local name = GetTargetResource()
    if not options or not name then return options end

    if name == 'ox_target' then
        return fixOX(options)
    elseif name == 'qb-target' then
        return fixQB(options)
    end

    return {}
end