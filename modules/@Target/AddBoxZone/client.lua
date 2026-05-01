--- Create target box zone.
--- @param name string Box name
--- @param coords table Box cooords {x,y,z}
--- @param size table Box size {x,y,z}
--- @param heading number Box heading
--- @param options table Options
--- @param debug? boolean Debug
function AddBoxZone(name, coords, size, heading, options, debug)
    local tName = GetTargetResource()
    options = FixOptions(options)

    local target

    if tName == 'ox_target' then
        target = Target:addBoxZone({
            coords = coords,
            size = size,
            rotation = heading,
            debug = debug or false,
            options = options,
        })
    elseif tName == 'qb-target' then
        Target:AddBoxZone(name, coords, size.x, size.y, {
            name = name,
            debugPoly = debug or false,
            heading = heading,
            minZ = coords.z - (size.z * 0.5),
            maxZ = coords.z + (size.z * 0.5),
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