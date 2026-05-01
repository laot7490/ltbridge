--- Remove target options on non-networked entity(s).
--- @param entities table|number Entity(s)
--- @param optionNames string|table Option(s)
function RemoveLocalEntity(entities, optionNames)
    local name = GetTargetResource()

    if name == 'ox_target' then
        Target:removeLocalEntity(entities, optionNames)
    elseif name == 'qb-target' then
        Target:RemoveTargetEntity(entities, optionNames)
    end
end