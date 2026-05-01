--- Create target options on non-networked entity(s).
--- @param entities table|number Entity(s)
--- @param options table Options
function AddLocalEntity(entities, options)
    local name = GetTargetResource()
    options = FixOptions(options)

    if name == 'ox_target' then
        Target:addLocalEntity(entities, options)
    elseif name == 'qb-target' then
        Target:AddTargetEntity(entities, {
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end