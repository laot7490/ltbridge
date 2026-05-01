--- Check if a table contains a value.
--- @param tbl table
--- @param value any
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return boolean
--- @ltbridge export: Contains
function TableContains(tbl, value, iter)
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs
    for _, v in iterator(tbl) do
        if v == value then return true end
    end
    return false
end
