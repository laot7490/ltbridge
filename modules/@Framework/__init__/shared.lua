local frameworkName = nil
local GetResourceState = GetResourceState

ESX = nil
QBCore = nil
QBX = nil

local function isStarted(res)
    return GetResourceState(res) == 'started'
end

local function detectFramework()
    if isStarted('es_extended') then
        ESX = exports.es_extended:getSharedObject()
        frameworkName = 'es_extended'
    elseif isStarted('qb-core') and not isStarted('qbx_core') then
        QBCore = exports['qb-core']:GetCoreObject()
        frameworkName = 'qb-core'
    elseif isStarted('qbx_core') then
        QBX = exports.qbx_core
        frameworkName = 'qbx_core'
    end

    if not frameworkName then
        printf('error', 'No supported framework found.')
    end
end

--- Returns framework name.
--- @return 'es_extended'|'qb-core'|'qbx_core'|nil
--- @ltbridge export: GetResource
function GetFramework()
    return frameworkName
end

detectFramework()
