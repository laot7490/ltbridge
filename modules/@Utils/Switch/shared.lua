--- Basic switch statement for Lua.
---```lua
---local result = LT.Utils.Switch(value, {
---    [1] = function() return 'one' end,
---    [2] = function() return 'two' end,
---    default = function() return 'default' end
---})
---```
---@generic T
---@param value T The value to match against the cases
---@param cases table<T|'default', fun(): any> Table with case functions and an optional default.
---@return any|nil result The return value of the matched case function, or nil if none matched
function Switch(value, cases)
    local fn = cases[value] or cases.default

    if type(fn) == "function" then
        local ok, result = pcall(fn)
        if ok then return result end
    end

    return nil
end
