local resourceName = nil

local list = {
    ['ps-dispatch'] = { providers = { 'lb-tablet' } },
    ['cd_dispatch'] = {},
    ['tk_dispatch'] = {},
    ['qs-dispatch'] = {},
    ['emergencydispatch'] = {},
    ['wasabi_mdt'] = {},
    ['linden_outlawalert'] = {}
}

--- Returns dispatch resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetDispatchResource()
    return resourceName
end

--- Force set dispatch resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetDispatchResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Dispatch resource %s not found.', name)
    resourceName = name
end

local resource = DetectResource(list, 'dispatch')
if resource then
    SetDispatchResource(resource)
end

-- Huge thx to community_bridge idk what i am doing in this module xD

local adapters = {
    ['ps-dispatch'] = function(data)
        local alertData = {
            message = data.message or "No message",
            code = data.code or '10-80',
            icon = data.icon or 'fas fa-question',
            priority = data.priority or 2,
            coords = data.coords or GetEntityCoords(PlayerPedId()),
            vehicle = data.vehicle,
            plate = data.plate,
            alertTime = data.time and (data.time / 1000) or nil,
            radius = data.blipData and data.blipData.radius or 0,
            sprite = data.blipData and data.blipData.sprite or 161,
            color = data.blipData and data.blipData.color or 84,
            scale = data.blipData and data.blipData.scale or 1.0,
            length = 2,
            sound = "Lose_1st",
            sound2 = "GTAO_FM_Events_Soundset",
            offset = false,
            flash = data.blipData and data.blipData.flash or false,
            jobs = data.jobs or data.job or "police"
        }
        exports["ps-dispatch"]:CustomAlert(alertData)
    end,
    ['cd_dispatch'] = function(data)
        local pData = exports['cd_dispatch']:GetPlayerInfo()
        TriggerServerEvent('cd_dispatch:AddNotification', {
            job_table = data.jobs,
            coords = data.coords,
            title = data.message,
            message = data.message,
            flash = 0,
            unique_id = pData.unique_id,
            sound = 1,
            blip = {
                sprite = data.blipData.sprite,
                scale = data.blipData.scale,
                colour = data.blipData.color,
                flashes = false,
                text = data.message,
                time = (data.time / 1000),
                radius = 0,
            }
        })
    end,
    ['tk_dispatch'] = function(data)
        local alertData = {
            title = data.message,
            code = data.code or '10-80',
            priority = 'Priority ' .. (data.priority or 2),
            coords = data.coords or GetEntityCoords(PlayerPedId()),
            showLocation = true,
            showGender = false,
            playSound = true,
            blip = {
                color = data.blipData.color or 3,
                sprite = data.blipData.sprite or 1,
                scale = data.blipData.scale or 0.8,
            },
            jobs = data.jobs or { 'police' },
        }
        exports.tk_dispatch:addCall(alertData)
    end,
    ['qs-dispatch'] = function(data)
        local customData = {
            job = data.jobs or { 'police' },
            callLocation = data.coords or vec3(0.0, 0.0, 0.0),
            callCode = {
                code = data.code or '10-80',
                snippet = data.snippet or 'General Alert'
            },
            message = data.message,
            flashes = false,
            image = nil,
            blip = {
                sprite = data.blipData.sprite or 1,
                scale = data.blipData.scale or 1.0,
                colour = data.blipData.color or 1,
                flashes = false,
                text = data.message or "Alert",
                time = data.length and (data.time * 1000) or 20000
            },
            otherData = {
                {
                    text = data.name or 'N/A',
                    icon = data.icon or 'fas fa-question'
                }
            }
        }

        exports['qs-dispatch']:getSSURL(function(image)
            customData.image = image or customData.image
            TriggerServerEvent('qs-dispatch:server:CreateDispatchCall', customData)
        end)
    end,
    ['emergencydispatch'] = function(data)
        local ped = PlayerPedId()

        local job = data.job or data.jobs[1] or 'police'
        local message = data.message or 'Alert'
        local coords = data.coords or GetEntityCoords(ped)

        TriggerServerEvent('emergencydispatch:emergencycall:new', job, message, coords, true)
    end,
    ['wasabi_mdt'] = function(data)
        local fallbackCoords = GetEntityCoords(PlayerPedId())
        local alertData = {
            type = data.code or '10-80',
            title = data.code or '10-80',
            description = data.message or "No message provided",
            location = { data.coords.x, data.coords.y, data.coords.z } or { fallbackCoords.x, fallbackCoords.y, fallbackCoords.z },
            coords = { data.coords.x, data.coords.y, data.coords.z } or { fallbackCoords.x, fallbackCoords.y, fallbackCoords.z },
        }
        exports.wasabi_mdt:CreateDispatch(alertData)
    end,
    ['linden_outlawalert'] = function(data)
        local ped = PlayerPedId()
        TriggerServerEvent('wf-alerts:svNotify', {
            dispatchData = {
                displayCode = data.code or '211',
                description = data.message or "Alert",
                isImportant = 0,
                recipientList = data.jobs or { 'police' },
                length = data.time or '10000',
                infoM = data.icon or 'fas fa-question',
                info = data.message or "Alert"
            },
            caller = 'Anonymous',
            coords = data.coords or GetEntityCoords(ped)
        })
    end
}

--- Send dispatch alert to given jobs.
--- @param data table Dispatch data
--- @ltbridge export: Send
function SendDispatch(data)
    local resource = GetDispatchResource()
    ltassert(resource, 'dispatch resource not found.')
    local adapter = adapters[resource]
    ltassert(adapter, 'adapter not found.')
    adapter(data)
end
