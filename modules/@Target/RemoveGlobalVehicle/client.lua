--- Remove all target options from all vehicles.
--- @param options table Options
function RemoveGlobalVehicle(options)
    local name = GetTargetResource()
    options = FixOptions(options)
    
    if name == 'ox_target' then
        local labels = {}
        for k, v in pairs(options) do
            table.insert(labels, v.name)
        end
        Target:removeGlobalVehicle(labels)
    elseif name == 'qb-target' then
        local labels = {}
        for k, v in pairs(options) do
            table.insert(labels, v.label)
        end
        Target:RemoveGlobalVehicle(labels)
    end
end