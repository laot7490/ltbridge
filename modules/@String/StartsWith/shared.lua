--- Check if string starts with given prefix.
--- @param str string
--- @param prefix string
--- @return boolean
--- @ltbridge export: StartsWith
function StringStartsWith(str, prefix)
    return str:sub(1, #prefix) == prefix
end
