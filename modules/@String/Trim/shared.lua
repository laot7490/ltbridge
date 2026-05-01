--- Trim whitespace from both ends of a string.
--- @param str string
--- @return string
--- @ltbridge export: Trim
function StringTrim(str)
    return (str:gsub('^%s+', ''):gsub('%s+$', ''))
end
