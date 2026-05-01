--- Remove target options from networked entity(s).
--- @param netids table|number Net id(s)
--- @param optionNames string|table Option name(s)
function RemoveNetworkedEntity(netids, optionNames)
    local name = GetTargetResource()

    if name == 'ox_target' then
        Target:removeEntity(netids, optionNames)
    elseif name == 'qb-target' then
        Target:RemoveTargetEntity(netids, optionNames)
    end
end