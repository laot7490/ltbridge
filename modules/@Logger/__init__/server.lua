local PerformHttpRequest = PerformHttpRequest
local CreateThread = CreateThread
local insert = table.insert
local string_format = string.format

local settings = {
    type = nil,
    webhook = "",
    folder = "logs",
    interval = 60000,
    fivemerrAPIKey = nil,
}

-- Waiting logs to write
local LOGGER_TXT_BUFFER = {}
local LOGGER_DISCORD_BUFFER = {}

--- Initialize logger.
--- **NOTE:** If using `txt` type, you need to create the folder manually `logs` (by default) in your resource folder.
--- @param logType 'discord'|'txt'|'fivemanage'|'fivemerr'
--- @param data? table { `webhook: string` (If using discord), `folder: string` (If using txt, optional), `interval: number` (optional), `fivemerrAPIKey: string` (If using fivemerr, optional) }
--- ```lua
--- LT.Logger.Init('discord', {
---     webhook = '', -- Webhook URL if using discord.
---     folder = 'custom_logs_folder', -- Custom folder if using txt logs. Must be manually created in resource directory.
---     fivemerrAPIKey = '', -- Fivemerr API key if using it.
---     interval = 60000, -- Log write/send interval to prevent spam or rate limits. (default: 60000 -> every minute)
--- })
--- ```
--- @ltbridge export: Init
function InitLogger(logType, data)
    if logType ~= 'discord' and logType ~= 'txt' and logType ~= 'fivemanage' and logType ~= 'fivemerr' then
        return printf('error', 'Please select a valid log type: ^4discord^7, ^4txt^7, ^4fivemanage^7, ^4fivemerr^7')
    end

    if logType == 'discord' then
        if not data or not data.webhook then return printf('error', 'Please provide a webhook for discord logger.') end
        settings.webhook = data.webhook
    elseif logType == 'txt' then
        if not data or not data.folder then
            data.folder = 'logs/'
        else
            settings.folder = data.folder
        end
    elseif logType == 'fivemanage' then
        if GetResourceState("fmsdk") == "missing" then
            return printf('error', '^3fivemanage^7 log system selected but ^3fmsdk^7 resource is missing.')
        end
    elseif logType == 'fivemerr' then
        if not data or not data.fivemerrAPIKey then return printf('error', 'Please provide a fivemerr API key for logger.') end
        settings.fivemerrAPIKey = data.fivemerrAPIKey
    end
    
    settings.type = logType
    
    if data and data.interval then 
        settings.interval = data.interval 
    end

    CreateThread(function()
        while true do
            Wait(settings.interval)
            
            if settings.type == 'txt' then
                if #LOGGER_TXT_BUFFER > 0 then
                    local date = os.date('%Y-%m-%d')
                    local path = settings.folder .. '/' .. date .. '.txt'
                    local existing = LoadResourceFile(LT_RESOURCE_NAME, path) or ""
                    local newData = existing .. table.concat(LOGGER_TXT_BUFFER)
                    SaveResourceFile(LT_RESOURCE_NAME, path, newData, -1)

                    LOGGER_TXT_BUFFER = {}
                end
            end

            if settings.type == 'discord' then
                if #LOGGER_DISCORD_BUFFER > 0 then
                    local embeds = {}
                    local toRemove = {}

                    for i, log in ipairs(LOGGER_DISCORD_BUFFER) do
                        if #embeds < 10 then
                            table.insert(embeds, {
                                color = log.color,
                                title = LT_RESOURCE_NAME,
                                fields = {
                                    {
                                        name = 'Log Message',
                                        value = '```' .. log.message .. '```',
                                        inline = false,
                                    }
                                },
                                footer = {
                                    text = "Created with ❤️ by Laot | LTBridge"
                                },
                                timestamp = log.timestamp,
                            })

                            table.insert(toRemove, i)
                        else
                            break
                        end
                    end
                    for i = #toRemove, 1, -1 do
                        table.remove(LOGGER_DISCORD_BUFFER, toRemove[i])
                    end

                    PerformHttpRequest(settings.webhook, function(status, text, headers) 
                        if status ~= 200 and status ~= 204 then
                            printf('error', 'Failed to send logs to discord. Status: %s - Response: %s', json.encode(status), json.encode(text))
                        end
                    end, 'POST', json.encode({
                        username = 'LTBridge Logger',
                        avatar_url = 'https://avatars.githubusercontent.com/u/70145288?v=4',
                        embeds = embeds,
                    }), { ['Content-Type'] = 'application/json' })
                end
            end

        end
    end)
end

--- Get current logger type.
--- @ltbridge internal
function GetLoggerType()
    return settings.type
end

--- Get current logger settings.
--- @ltbridge internal
function GetLoggerSettings()
    return settings
end

local adapters = {
    ['txt'] = function(message, status)
        local date = os.date('%H:%M:%S')
        local statusTable = {
            ['info'] = 'INFO',
            ['warn'] = 'WARN',
            ['error'] = 'ERROR',
        }

        local log
        local msg = '[%s] %s\n'
        if status ~= nil then
            msg = '[%s] %s: %s\n'
            log = string_format(msg, date, statusTable[status] or "INFO", message)
        else
            log = string_format(msg, date, message)
        end

        insert(LOGGER_TXT_BUFFER, log)
    end,
    ['discord'] = function(message, status)
        local timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        local message = tostring(message)
        local colors = {
            info = 3447003,
            warn = 16776960,
            error = 15158332,
        }
        insert(LOGGER_DISCORD_BUFFER, {
            color = colors[status] or 3447003,
            message = message,
            timestamp = timestamp
        })
    end,
    ['fivemanage'] = function(message, status)
        exports.fmsdk:LogMessage(status or 'info', message)
    end,
    ['fivemerr'] = function(message, status)
        local data = {
            level = status or 'info',
            message = tostring(message),
            resource = LT_RESOURCE_NAME,
        }
        PerformHttpRequest('https://api.fivemerr.com/v1/logs', function(status, text, headers)
            if status ~= 200 then
                printf('error', 'Failed to send log to Fivemerr API (HTTP %d): Please verify your API key is correct and the service is available.', status)
            end
        end, 'POST', json.encode(data), {
            ['Content-Type'] = 'application/json',
            ['Authorization'] = GetLoggerSettings().fivemerrAPIKey
        })
    end
}

--- Creates a log message.
--- Use `LT.Logger.Init()` before using this function.
--- @param message string The message to log.
--- @param status? 'info'|'warn'|'error' (optional)
--- @ltbridge export: Create
function CreateLog(message, status)
    local logType = GetLoggerType()
    if not logType then return printf('error', 'Logger not initialized. Please use ^3LT.Logger.Init()^7 first.') end
    local adapter = adapters[logType]
    if not adapter then return end
    adapter(message, status)
end