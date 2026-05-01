--- Format a number with thousand separators.
--- ```lua
--- LT.Math.FormatNumber(1234567) -- "1,234,567"
--- ```
--- @param num number
--- @return string
--- @ltbridge export: FormatNumber
function MathFormatNumber(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return formatted
end
