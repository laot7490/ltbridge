--- Check if player has item.
--- @param source number Player source
--- @param item string Item name
--- @param count? number Required count (optional)
--- @return boolean
function HasItem(source, item, count)
    return GetItemCountServer(source, item) >= (count or 1) or false
end