--- Linear interpolation between two values.
--- @param a number Start value
--- @param b number End value
--- @param t number Interpolation factor (0-1)
--- @return number
--- @ltbridge export: Lerp
function MathLerp(a, b, t)
    return a + (b - a) * t
end
