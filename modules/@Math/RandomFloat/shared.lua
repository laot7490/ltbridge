--- Get a random float in range.
--- @param min number
--- @param max number
--- @return number
--- @ltbridge export: RandomFloat
function MathRandomFloat(min, max)
    return min + math.random() * (max - min)
end
