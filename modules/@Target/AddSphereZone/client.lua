--- Create target sphere zone.
---@param name string Zone name
---@param coords table Zone coords
---@param radius number Radius
---@param options table Options
---@param debug? boolean Debug mode
function AddSphereZone(name, coords, radius, options, debug)
    local tName = GetTargetResource()
    options = FixOptions(options)

    local target

    if tName == 'ox_target' then
        target = Target:addSphereZone({
            coords = coords,
            radius = radius,
            name = name,
            debug = debug or false,
            options = options
        })
    elseif tName == 'qb-target' then
        Target:AddCircleZone(name, coords, radius, {
            name = name,
            debugPoly = debug or false,
        }, {
            options = options,
            distance = GetLargestDistance(options),
        })
        target = true
    end

    if target then
        AddZone(name)
    end
end