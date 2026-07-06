local laot = 'https://avatars.githubusercontent.com/u/70145288'
local string_format = string.format

local function stripPng(item)
    if string.find(item, ".png") then
        item = string.gsub(item, ".png", "")
    end
    return item
end

local function stripWebp(item)
    if string.find(item, ".webp") then
        item = string.gsub(item, ".webp", "")
    end
    return item
end

local adapters = {
    ['ox_inventory'] = function(item)
        local file = LoadResourceFile("ox_inventory", string_format("web/images/%s.png", item))
        local imagePath = file and string_format("nui://ox_inventory/web/images/%s.png", item)
        return imagePath or laot
    end,
    ['qs-inventory'] = function(item)
        local file = LoadResourceFile("qs-inventory", string_format("html/images/%s.png", item))
        local imagePath = file and string_format("nui://qs-inventory/html/images/%s.png", item)
        return imagePath or laot
    end,
    ['qb-inventory'] = function(item)
        local file = LoadResourceFile("qb-inventory", string_format("html/images/%s.png", item))
        local imagePath = file and string_format("nui://qb-inventory/html/images/%s.png", item)
        return imagePath or laot
    end,
    ['tgiann-inventory'] = function(item)
        local webpItem = stripWebp(item)
        local pngPath = LoadResourceFile("inventory_images", string_format("/images/%s.png", item))
        local webpPath = LoadResourceFile("inventory_images", string_format("/images/%s.webp", webpItem))
        local imagePath = pngPath and string_format("nui://inventory_images/images/%s.png", item) or
            webpPath and string_format("nui://inventory_images/images/%s.webp", webpItem)
        return imagePath or laot
    end,
    ['origen_inventory'] = function(item)
        local file = LoadResourceFile("origin", string_format("html/images/%s.png", item))
        local imagePath = file and string_format("nui://origen_inventory/html/images/%s.png", item)
        return imagePath or laot
    end,
    ['one_inventory'] = function(item)
        local file = LoadResourceFile("one_inventory", string_format("web/images/%s.png", item))
        local imagePath = file and string_format("nui://one_inventory/web/images/%s.png", item)
        return imagePath or laot
    end,
}

--- Returns item image path.
--- @param item string Item name
--- @return string|nil
function GetItemImage(item)
    local name = GetInventoryResource()
    ltassert(name, 'inventory resource not found. this function will return nil.')

    item = stripPng(item)

    return adapters[name](item)
end
