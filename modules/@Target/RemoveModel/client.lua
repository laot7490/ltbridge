--- Remove specified target options for specified model(s).
--- @param models table|number Model(s)
--- @param optionNames string|table Option name(s)
function RemoveModel(models, optionNames)
    local name = GetTargetResource()

    if name == 'ox_target' then
        Target:removeModel(models, optionNames)
    elseif name == 'qb-target' then
        Target:RemoveTargetModel(models, optionNames)
    end
end