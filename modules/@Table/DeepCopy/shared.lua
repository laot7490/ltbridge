--- Deep copy a table recursively.
--- @param tbl table
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: DeepCopy
function TableDeepCopy(tbl, iter)
    local copy = {}
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs

    for k, v in iterator(tbl) do
        if type(v) == 'table' then
            copy[k] = TableDeepCopy(v, iter)
        else
            copy[k] = v
        end
    end

    return setmetatable(copy, getmetatable(tbl))
end
