-- Main file of LT Bridge.
-- This file is automatically included in the build process.
-- Any changes here will directly affect the final build.
-- Edit with caution.

-- Global variables of LTBridge.
__LT_RESOURCE_NAME = GetCurrentResourceName()
__LT_VERSION = '0.0.0'
__LT_DISABLE_DEBUG = false

local print = print
local format = string.format

--- Returns the current version of LTBridge.
--- @return string
--- @ltbridge global
function GetBridgeVersion()
    return __LT_VERSION
end

--- Internal print/debug function of LTBridge, use this and not the original `print()` when creating modules.
--- @param type? 'error'|'warning'|'info'
--- @param message string Print message
--- @param ...? any Additional parameters
--- @ltbridge internal
function printf(type, message, ...)
    if __LT_DISABLE_DEBUG and type ~= 'error' then
        return
    end

    local info = debug.getinfo(2, 'Sl')
    local source = info and info.short_src or 'unknown'
    local line = info and info.currentline or -1

    local prefix = {
        error = '^6[LTBridge %s] ^1ERROR:',
        warning = '^6[LTBridge %s] ^3WARNING:',
        info = '^6[LTBridge %s] ^6INFO:',
    }

    source = format(' %s:%d: ', source, line)
    if source:find('modules', 1, true) then
        source = ' '
    end

    local label = prefix[type] or prefix.info
    message = tostring(message)

    print(
        format(label, __LT_VERSION)
        .. source
        .. format(message, ...)
        .. '^7'
    )
end
