local debugMode = 1
local print = print
local format = string.format

local function canSend(_type)
    if debugMode == 0 then return false
    elseif debugMode == 1 and (_type ~= 'error') then return false
    elseif debugMode == 2 and (_type ~= 'error' and _type ~= 'warning') then return false
    elseif debugMode == 3 and (_type == 'verbose') then return false end
    return true
end

--- Set debug mode.
--- **0**: `Disabled` (Not Recommended)
--- **1**: `Errors` (Default)
--- **2**: `Errors + Warnings`
--- **3**: `Except Verbose`
--- **4**: `All Messages`
--- @param mode? number
--- @ltbridge export: SetMode
function SetDebugMode(mode)
    debugMode = mode or 1
end

local debugTypes <const> = {
   ['success'] = '^2[SUCCESS]^7',
   ['error'] = '^1[ERROR]^7',
   ['warning'] = '^3[WARNING]^7',
   ['info'] = '^4[INFO]^7',
   ['verbose'] = '^5[VERBOSE]^7',
}

--- Prints a formatted and detailed (with file and line info) debug message.
--- @param message string Message to print.
--- @param type? 'info'|'success'|'error'|'warning'|'verbose'
--- @param ...? any Format parameters.
--- @ltbridge export: Detailed
function DebugDetailed(message, type, ...)
    if not type then type = 'verbose' end
    if not canSend(type) then return end
    local prefix = debugTypes[type]
    
    local info = debug.getinfo(2, 'Sl')
    local source = info and info.short_src or 'unknown'
    local line = info and info.currentline or -1

    source = source:gsub("^@", "")
    local short = source:match("([^/]+/[^/]+%.lua)$") or source:match("([^/]+%.lua)$") or source

    print(format('^3[%s:%d]^7 %s %s^7', short, line, prefix, format(message, ...)))
end

--- Prints a formatted debug message.
--- @param message string Message to print.
--- @param type? 'info'|'success'|'error'|'warning'|'verbose'
--- @param ...? any Format parameters.
--- @ltbridge export: Print
function DebugPrint(message, type, ...)
    if not type then type = 'verbose' end
    if not canSend(type) then return end
    local prefix = debugTypes[type]
    
    print(format('%s %s', prefix, format(message, ...)))
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
