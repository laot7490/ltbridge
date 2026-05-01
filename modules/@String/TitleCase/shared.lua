--- Capitalize first letter of each word.
--- ```lua
--- LT.String.TitleCase('hello world') -- 'Hello World'
--- ```
--- @param str string
--- @return string
--- @ltbridge export: TitleCase
function StringTitleCase(str)
    return (str:gsub('(%a)([%w]*)', function(first, rest)
        return first:upper() .. rest:lower()
    end))
end
