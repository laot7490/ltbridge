--- Add target options to all vehicles.
--- @param options table Options
function AddGlobalVehicle(options)
    local name = GetTargetResource()
    options = FixOptions(options)
    
    if name == 'ox_target' then
        Target:addGlobalVehicle(options)
    elseif name == 'qb-target' then
        Target:AddGlobalVehicle({
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end