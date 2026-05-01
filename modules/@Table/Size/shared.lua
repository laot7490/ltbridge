--- Get size of a table (works for non-sequential tables by default).
--- @param tbl table
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return number
--- @ltbridge export: Size
function TableSize(tbl, iter)
    local count = 0
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs
    for _ in iterator(tbl) do count = count + 1 end
    return count
end
