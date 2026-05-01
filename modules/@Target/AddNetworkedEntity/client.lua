--- Create target options on networked entity(s).
--- @param netids table|number Net id(s)
--- @param options table Options
function AddNetworkedEntity(netids, options)
    local name = GetTargetResource()
    options = FixOptions(options)

    if name == 'ox_target' then
        Target:addEntity(netids, options)
    elseif name == 'qb-target' then
        Target:AddTargetEntity(netids, {
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end