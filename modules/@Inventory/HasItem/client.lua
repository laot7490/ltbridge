--- Check if player has item.
--- @param item string Item name
--- @param count? number Required count (default: 1)
--- @return boolean
function HasItem(item, count)
    return GetItemCountClient(item) >= (count or 1) or false
end
