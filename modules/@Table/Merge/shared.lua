--- Merge two tables. Override values take priority.
--- Performs deep merge for nested tables.
--- @param base table
--- @param override table
--- @param iter? boolean|function If true, uses ipairs. If function, uses as iterator. Default pairs.
--- @return table
--- @ltbridge export: Merge
function TableMerge(base, override, iter)
    local iterator = (iter == true and ipairs) or (type(iter) == "function" and iter) or pairs

    local function deepCopy(t)
        local copy = {}
        for k, v in iterator(t) do
            copy[k] = type(v) == 'table' and deepCopy(v) or v
        end
        return setmetatable(copy, getmetatable(t))
    end

    local result = deepCopy(base)
    for k, v in iterator(override) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = TableMerge(result[k], v, iter)
        else
            result[k] = v
        end
    end
    return result
end
