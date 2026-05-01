--- Remove all target options from all players.
--- @param options? table Options
function RemoveGlobalPlayer(options)
    local name = GetTargetResource()
    if options then options = FixOptions(options) end
    
    if name == 'ox_target' then
        Target:removeGlobalPlayer(options)
    elseif name == 'qb-target' then
        Target:RemoveGlobalPlayer(options)
    end
end