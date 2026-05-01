--- Get all keys of a table.
--- @param tbl table
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: Keys
function TableKeys(tbl, iter)
    local keys = {}
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs
    for k in iterator(tbl) do
        keys[#keys + 1] = k
    end
    return keys
end
