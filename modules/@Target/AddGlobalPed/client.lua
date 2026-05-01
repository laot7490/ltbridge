--- Add target options to peds (excluding players).
--- @param options table Options
function AddGlobalPed(options)
    local name = GetTargetResource()
    options = FixOptions(options)
    
    if name == 'ox_target' then
        Target:addGlobalPed(options)
    elseif name == 'qb-target' then
        Target:AddGlobalPed({
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end