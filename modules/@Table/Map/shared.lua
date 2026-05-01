--- Map a table by a transform function.
--- ```lua
--- local doubled = LT.Table.Map({1, 2, 3}, function(v) return v * 2 end)
--- -- {2, 4, 6}
--- ```
--- @param tbl table
--- @param transform fun(value: any, key: any): any
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: Map
function TableMap(tbl, transform, iter)
    local result = {}
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs

    for k, v in iterator(tbl) do
        result[k] = transform(v, k)
    end

    return result
end
