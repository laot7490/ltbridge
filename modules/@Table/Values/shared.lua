--- Get all values of a table.
--- @param tbl table
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: Values
function TableValues(tbl, iter)
    local values = {}
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs
    for _, v in iterator(tbl) do
        values[#values + 1] = v
    end
    return values
end
