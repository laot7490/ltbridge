--- Check if string ends with given suffix.
--- @param str string
--- @param suffix string
--- @return boolean
--- @ltbridge export: EndsWith
function StringEndsWith(str, suffix)
    return suffix == '' or str:sub(-#suffix) == suffix
end
