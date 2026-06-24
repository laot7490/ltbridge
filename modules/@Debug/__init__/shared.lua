local debugMode = 1
local print = print
local string_format = string.format
local tonumber = tonumber

local debugTypes <const> = {
    ['success'] = { mode = 3, color = 2 },
    ['error'] = { mode = 1, color = 1 },
    ['warning'] = { mode = 2, color = 3 },
    ['info'] = { mode = 3, color = 4 },
    ['verbose'] = { mode = 4, color = 5 },
}

local function handleException(result, value)
    if type(value) == 'function' then
        return tostring(value)
    end
    return result
end

--- Format the data to a string.
--- @param ... any Data to format.
--- @return string Formatted data.
local function format(message, ...)
    local data = { ... }

    for i = 1, #data do
        local v = data[i]

        if type(v) == "table" then
            data[i] = json.encode(v, {
                indent = true,
                exception = handleException
            })
        elseif type(v) == "boolean" then
            data[i] = v and "true" or "false"
        elseif type(v) ~= "string" then
            data[i] = tostring(v)
        end
    end

    return string_format(message, table.unpack(data))
end

--- Set debug mode.
---
--- **0**: `Disabled` (Not Recommended)
---
--- **1**: `Errors` (Default)
---
--- **2**: `Errors + Warnings`
---
--- **3**: `Except Verbose`
---
--- **4**: `All Messages`
---
--- @param mode? number
--- @ltbridge export: SetMode
function SetDebugMode(mode)
    debugMode = mode or 1
end

--- Prints a formatted and detailed (with file and line info) debug message.
--- @param message string Message to print.
--- @param type? 'info'|'success'|'error'|'warning'|'verbose'
--- @param ...? any Format parameters.
--- @ltbridge export: Detailed
function DebugDetailed(message, type, ...)
    if not type then type = 'verbose' end
    local data = debugTypes[type]
    if not data then return end
    if tonumber(debugMode) < tonumber(data.mode) then return end

    local info = debug.getinfo(2, 'Sl')
    local source = info and info.short_src or 'unknown'
    local line = info and info.currentline or -1

    print(string_format('^%d[%s] %s:%d: ^7%s^7', data.color, type:upper(), source, line, format(message, ...)))
end

--- Prints a formatted debug message.
--- @param message string Message to print.
--- @param type? 'info'|'success'|'error'|'warning'|'verbose'
--- @param ...? any Format parameters.
--- @ltbridge export: Print
function DebugPrint(message, type, ...)
    if not type then type = 'verbose' end
    local data = debugTypes[type]
    if not data then return end
    if tonumber(debugMode) < tonumber(data.mode) then return end

    print(string_format('^%d[%s]^7 %s^7', data.color, type:upper(), format(message, ...)))
end

--- Send a info debug mesage.
--- @param message string Message to print.
--- @param ...? any Format parameters.
--- @ltbridge export: Info
function DebugInfo(message, ...)
    DebugPrint(message, 'info', ...)
end

--- Send a success debug mesage.
--- @param message string Message to print.
--- @param ...? any Format parameters.
--- @ltbridge export: Success
function DebugSuccess(message, ...)
    DebugPrint(message, 'success', ...)
end

--- Send a error debug mesage.
--- @param message string Message to print.
--- @param ...? any Format parameters.
--- @ltbridge export: Error
function DebugError(message, ...)
    DebugPrint(message, 'error', ...)
end

--- Send a warning debug mesage.
--- @param message string Message to print.
--- @param ...? any Format parameters.
--- @ltbridge export: Warn
function DebugWarn(message, ...)
    DebugPrint(message, 'warning', ...)
end

--- Send a verbose debug mesage.
--- @param message string Message to print.
--- @param ...? any Format parameters.
--- @ltbridge export: Verbose
function DebugVerbose(message, ...)
    DebugPrint(message, 'verbose', ...)
end
