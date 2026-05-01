--- Add target options to all players.
--- @param options table Options
function AddGlobalPlayer(options)
    local name = GetTargetResource()
    options = FixOptions(options)
    
    if name == 'ox_target' then
        Target:addGlobalPlayer(options)
    elseif name == 'qb-target' then
        Target:AddGlobalPlayer({
            options = options,
            distance = GetLargestDistance(options)
        })
    end
end