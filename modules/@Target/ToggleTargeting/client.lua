--- Toggle on/off targeting.
--- @param state boolean `true` Can target | `false` Can't target.
function ToggleTargeting(state)
    local name = GetTargetResource()
    if not Target or not name then return end

    if name == 'ox_target' then
        Target:disableTargeting(not state)
    elseif name == 'qb-target' then
        Target:AllowTargeting(state)
    end
end