--- Round a number to given decimal places.
--- @param num number
--- @param decimals? number Defaults to 0
--- @return number
--- @ltbridge export: Round
function MathRound(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end
