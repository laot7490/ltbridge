--- Filter a table by a predicate function.
--- ```lua
--- local evens = LT.Table.Filter({1, 2, 3, 4}, function(v) return v % 2 == 0 end)
--- -- {2, 4}
--- ```
--- @param tbl table
--- @param predicate fun(value: any, key: any): boolean
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: Filter
function TableFilter(tbl, predicate, iter)
    local result = {}
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs

    for k, v in iterator(tbl) do
        if predicate(v, k) then
            result[#result + 1] = v
        end
    end

    return result
end
