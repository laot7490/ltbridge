--- Register usable item on framework default format.
--- @param name string Item name
--- @param cb fun(source: number, item?: table)
function RegisterUsableItem(name, cb)
    if ESX then
        ESX.RegisterUsableItem(name,function(source)
            cb(source)
        end)
    elseif QBCore then
        local func = function(src, item, itemData)
            itemData = itemData or item
            itemData.metadata = itemData.metadata or itemData.info or {}
            itemData.slot = itemData.id or itemData.slot
            cb(src, itemData)
        end
        QBCore.Functions.CreateUseableItem(name, func)
    elseif QBX then
        local func = function(src, item, itemData)
            itemData = itemData or item
            itemData.metadata = itemData.metadata or itemData.info or {}
            itemData.slot = itemData.id or itemData.slot
            cb(src, itemData)
        end
        QBX:CreateUseableItem(name, func)
    end
end