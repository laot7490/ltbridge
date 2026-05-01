--- Capitalize first letter of a string.
--- @param str string
--- @return string
--- @ltbridge export: Capitalize
function StringCapitalize(str)
    return str:sub(1, 1):upper() .. str:sub(2)
end
