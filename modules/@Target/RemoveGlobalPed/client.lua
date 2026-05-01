--- Remove all target options from all Peds.
--- @param options? table Options
function RemoveGlobalPed(options)
    local name = GetTargetResource()
    if options then options = FixOptions(options) end
    
    if name == 'ox_target' then
        Target:removeGlobalPed(options)
    elseif name == 'qb-target' then
        Target:RemoveGlobalPed(options)
    end
end