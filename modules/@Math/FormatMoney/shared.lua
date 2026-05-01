--- Format a number as money with currency symbol.
--- ```lua
--- LT.Math.FormatMoney(1234567) -- "$1,234,567"
--- LT.Math.FormatMoney(1234567, '€') -- "€1,234,567"
--- ```
--- @param num number
--- @param symbol? string Currency symbol, defaults to "$"
--- @return string
--- @ltbridge export: FormatMoney
function MathFormatMoney(num, symbol)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = formatted:gsub('^(-?%d+)(%d%d%d)', '%1,%2')
        if k == 0 then break end
    end
    return (symbol or '$') .. formatted
end
