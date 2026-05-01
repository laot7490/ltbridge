local adapters = {
    ['ox_fuel'] = function(vehicle, fuel)
        local newFuel = (Entity(vehicle).state.fuel or 0) + fuel
        Entity(vehicle).state.fuel = newFuel
    end,
    ['x-fuel'] = function(vehicle, fuel)
        Fuel:SetFuel(vehicle, fuel)
    end,
    default = function(vehicle, fuel)
        Fuel:SetFuel(vehicle, fuel)
    end,
    fallback = function(vehicle, fuel)
        SetVehicleFuelLevel(vehicle, fuel)
    end
}

--- Set fuel percentage of vehicle.
--- @param vehicle number Vehicle entity.
--- @param fuel number Fuel level to assign.
function SetFuel(vehicle, fuel)
    if not DoesEntityExist(vehicle) then return end

    local adapter = adapters.fallback
    local resource = GetFuelResource()

    if resource then
        if adapters[resource] then
            adapter = adapters[resource]
        else
            adapter = adapters.default
        end
    end

    adapter(vehicle, fuel)
end