-- Main init of LT Bridge
-- This file is automatically included in the build.
-- Any changes here will directly affect the final build.
-- Edit with caution.

-- For internal use.
LT_RESOURCE_NAME = GetCurrentResourceName()

local print = print
local format = string.format

-- Do not change this.
LT_DISABLE_DEBUG = false
--- Internal print/debug function of LTBridge, use this and not the original `print()` when creating modules.
--- @param type? 'error'|'warning'
--- @param message string Print message
--- @param ...? any Additional parameters
--- @ltbridge internal
--- @diagnostic disable-next-line: lowercase-global
function printf(type, message, ...)
    if LT_DISABLE_DEBUG and type ~= 'error' then return end -- Print error messages always.
    local prefix = {
        error = '^1[LTBRIDGE] ERROR:^7 ',
        warning = '^3[LTBRIDGE] WARN:^7 ',
    }
    print((prefix[type] and prefix[type] or '^7 ') .. format(message, ...) .. '^7')
end