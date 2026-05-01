--- Map a value from one range to another.
--- ```lua
--- LT.Math.MapRange(50, 0, 100, 0, 1) -- 0.5
--- ```
--- @param value number
--- @param inMin number
--- @param inMax number
--- @param outMin number
--- @param outMax number
--- @return number
--- @ltbridge export: MapRange
function MathMapRange(value, inMin, inMax, outMin, outMax)
    if inMin == inMax then return outMin end
    return outMin + (value - inMin) * (outMax - outMin) / (inMax - inMin)
end
