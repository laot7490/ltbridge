local PlayerPedId = PlayerPedId
local PlayerId = PlayerId
local GetPlayerServerId = GetPlayerServerId
local GetVehiclePedIsIn = GetVehiclePedIsIn
local GetPedInVehicleSeat = GetPedInVehicleSeat
local GetEntityCoords = GetEntityCoords
local GetSelectedPedWeapon = GetSelectedPedWeapon
local IsEntityDead = IsEntityDead

--- @class Cache
--- @field ped number Entity ID of current player ped
--- @field playerId number Player ID
--- @field serverId number Server ID of current player
--- @field vehicle number|false Entity ID of current vehicle or false
--- @field seat number|false Seat index or false
--- @field weapon number|false Weapon hash or false
--- @field coords vector3 Current coordinates updated every 500ms
--- @field isDead boolean True if player is dead
local cache = {}
local listeners = {}

--- Get a specific cache value or the whole table.
--- @param key? 'ped'|'vehicle'|'seat'|'weapon'|'coords'|'isDead'|'playerId'|'serverId'
--- @return any
--- @ltbridge export: Get
function GetCache(key)
    if key then return cache[key] end
    return cache
end

--- Listen for changes in cache values.
--- ```lua
--- LT.Cache.OnChange('vehicle', function(vehicle, oldVehicle)
---     print('Vehicle state changed', vehicle)
--- end)
--- ```
--- @param key string The cache key to listen for ('vehicle', 'seat', 'weapon', 'isDead')
--- @param cb fun(newValue: any, oldValue: any)
--- @ltbridge export: OnChange
function OnCacheChange(key, cb)
    if not listeners[key] then listeners[key] = {} end
    table.insert(listeners[key], cb)
end

local function triggerListeners(key, newValue, oldValue)
    if not listeners[key] then return end
    for i = 1, #listeners[key] do
        listeners[key][i](newValue, oldValue)
    end
end

CreateThread(function()
    local ped = PlayerPedId()
    cache.playerId = PlayerId()
    cache.serverId = GetPlayerServerId(cache.playerId)
    cache.ped = ped
    cache.coords = GetEntityCoords(ped)
    cache.vehicle = false
    cache.seat = false
    cache.weapon = false
    cache.isDead = IsEntityDead(ped)

    while true do
        ped = PlayerPedId()

        if ped ~= cache.ped then
            local oldPed = cache.ped
            cache.ped = ped
            triggerListeners('ped', ped, oldPed)
        end

        cache.coords = GetEntityCoords(ped)

        ---@type number|false
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 then vehicle = false end
        
        if vehicle ~= cache.vehicle then
            local oldVehicle = cache.vehicle
            cache.vehicle = vehicle
            triggerListeners('vehicle', vehicle, oldVehicle)
        end

        if vehicle then
            ---@type number|false
            local seat = false
            for i = -1, 6 do
                if GetPedInVehicleSeat(vehicle, i) == ped then
                    seat = i
                    break
                end
            end
            if seat ~= cache.seat then
                local oldSeat = cache.seat
                cache.seat = seat
                triggerListeners('seat', seat, oldSeat)
            end
        else
            if cache.seat ~= false then
                local oldSeat = cache.seat
                cache.seat = false
                triggerListeners('seat', false, oldSeat)
            end
        end

        ---@type number|false
        local weapon = GetSelectedPedWeapon(ped)
        if weapon == `WEAPON_UNARMED` then weapon = false end
        if weapon ~= cache.weapon then
            local oldWeapon = cache.weapon
            cache.weapon = weapon
            triggerListeners('weapon', weapon, oldWeapon)
        end

        local isDead = IsEntityDead(ped)
        if isDead ~= cache.isDead then
            local oldState = cache.isDead
            cache.isDead = isDead
            triggerListeners('isDead', isDead, oldState)
        end

        Wait(500)
    end
end)
