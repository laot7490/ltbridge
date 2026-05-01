--- Create target options for specified model(s).
--- @param models table|number Model(s)
--- @param options table Options
function AddModel(models, options)
    local name = GetTargetResource()
    options = FixOptions(options)

    if name == 'ox_target' then
        Target:addModel(models, options)
    elseif name == 'qb-target' then
        Target:AddTargetModel(models, {
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end