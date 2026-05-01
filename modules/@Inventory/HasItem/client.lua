--- Check if player has item.
--- @param item string Item name
--- @param count? number Required count (optional)
--- @return boolean
function HasItem(item, count)
    return GetItemCountClient(item) >= (count or 1) or false
end