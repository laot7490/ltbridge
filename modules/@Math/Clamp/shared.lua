--- Clamp a value between min and max.
--- @param value number
--- @param min number
--- @param max number
--- @return number
--- @ltbridge export: Clamp
function MathClamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end
