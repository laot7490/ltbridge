local DoesEntityExist = DoesEntityExist

local adapters = {
    ['ox_fuel'] = function(vehicle)
        return Entity(vehicle).state.fuel
    end,
    ['x-fuel'] = function(vehicle)
        local level, _ = Fuel:getFuel(vehicle)
        return level
    end,
    default = function(vehicle)
        return Fuel:GetFuel(vehicle)
    end,
    fallback = function(vehicle)
        return GetVehicleFuelLevel(vehicle)
    end
}

--- Get fuel percentage of vehicle.
--- @param vehicle number Vehicle entity.
--- @return number Fuel
function GetFuel(vehicle)
    if not DoesEntityExist(vehicle) then return 0.0 end

    local adapter = adapters.fallback
    local resource = GetFuelResource()

    if resource then
        if adapters[resource] then
            adapter = adapters[resource]
        else
            adapter = adapters.default
        end
    end

    return adapter(vehicle)
end