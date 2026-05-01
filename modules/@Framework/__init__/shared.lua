local GetResourceState = GetResourceState
local resourceName = nil

ESX = nil
QBCore = nil
QBX = nil

local function isStarted(res)
    return GetResourceState(res) ~= 'missing'
end

local function detectFramework()
    if isStarted('es_extended') then
        ESX = exports.es_extended:getSharedObject()
        resourceName = 'es_extended'
    elseif isStarted('qb-core') and not isStarted('qbx_core') then
        QBCore = exports['qb-core']:GetCoreObject()
        resourceName = 'qb-core'
    elseif isStarted('qbx_core') then
        QBX = exports.qbx_core
        resourceName = 'qbx_core'
    end

    if not resourceName then
        printf('error', 'No supported framework found.')
    end
end

--- Returns framework name.
--- @return 'es_extended'|'qb-core'|'qbx_core'|nil
--- @ltbridge export: GetResource
function GetFramework()
    return resourceName
end

detectFramework()