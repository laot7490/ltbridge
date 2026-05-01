--- Split a string by delimiter.
--- ```lua
--- LT.String.Split('hello-world-test', '-') -- {'hello', 'world', 'test'}
--- ```
--- @param str string
--- @param delimiter string
--- @return table
--- @ltbridge export: Split
function StringSplit(str, delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = str:find(delimiter, from, true)

    while delim_from do
        result[#result + 1] = str:sub(from, delim_from - 1)
        from = delim_to + 1
        delim_from, delim_to = str:find(delimiter, from, true)
    end

    result[#result + 1] = str:sub(from)
    return result
end
