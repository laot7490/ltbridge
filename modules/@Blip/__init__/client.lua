local Blip = {}
Blip.__index = Blip

---@class BlipProperties
---@field label string Label of the blip
---@field coords? vector3 Coordinates of the blip
---@field entity? number Entity of the blip
---@field sprite? number Sprite of the blip
---@field color? number Color of the blip
---@field scale? number Scale of the blip
---@field shortRange? boolean|nil Whether the blip is a short range blip (default: true)
---@field display? number Display mode of the blip (default: 2)
---@field rotation? number Rotation of the blip
---@field alpha? number Alpha of the blip (default: 255)
---@field highDetail? boolean Whether the blip is a high detail blip (default: false)
---@field route? boolean Whether the blip is a route blip (default: false)
---@field routeColor? number Route color of the blip
---@field bright? boolean Whether the blip is a bright blip (default: false)
---@field flash? boolean Whether the blip is flashing (default: false)
---@field flashInterval? number Flash interval of the blip (default: 500ms)
---@field delete? fun(self: self) Delete the blip

---@type table Blip handlers
local blips = {}

local function validateCoords(coords)
    return type(coords) == 'vector3' or
        (type(coords) == 'table' and type(coords.x) == 'number' and type(coords.y) == 'number' and type(coords.z) == 'number')
end

--- Creates a new blip.
--- @param data BlipProperties Blip data
--- @return table|boolean Blip handler or false if failed
--- @ltbridge export: Create
function CreateBlip(data)
    local self = setmetatable({}, Blip)

    ltassert(data ~= nil, 'data is required')
    ltassert(type(data) == 'table', 'data must be a table')
    ltassert(data.label and type(data.label) == 'string', 'label is required and must be a valid string')
    ltassert(not (data.coords and data.entity), 'coords and entity cannot be used together')
    ltassert(data.coords or data.entity, 'coords or entity is required')

    self.type = data.coords and 'coord' or 'entity'

    if self.type == 'coord' and not validateCoords(data.coords) then
        printf('error', 'coords must be a valid vector3')
        return false
    end

    if self.type == 'entity' and (type(data.entity) ~= 'number' or not DoesEntityExist(data.entity)) then
        printf('error', 'entity must be a valid entity')
        return false
    end

    self.blip = self.type == 'entity' and AddBlipForEntity(data.entity) or
        AddBlipForCoord(data.coords.x + 0.0, data.coords.y + 0.0, data.coords.z + 0.0)

    SetBlipSprite(self.blip, data.sprite or 1)
    SetBlipScale(self.blip, (data.scale or 1.0) + 0.0)
    SetBlipColour(self.blip, data.color or 1)
    SetBlipAsShortRange(self.blip, data.shortRange ~= false)
    SetBlipDisplay(self.blip, data.display or 2)

    if data.rotation ~= nil then
        ltassert(type(data.rotation) == 'number', 'rotation must be a number')
        SetBlipRotation(self.blip, data.rotation)
    end
    if data.alpha ~= nil then
        ltassert(type(data.alpha) == 'number', 'alpha must be a number')
        ltassert(data.alpha >= 0 and data.alpha <= 255, 'alpha must be a number between 0 and 255')
        SetBlipAlpha(self.blip, data.alpha)
    end
    if data.highDetail ~= nil then
        ltassert(type(data.highDetail) == 'boolean', 'highDetail must be a boolean')
        SetBlipHighDetail(self.blip, data.highDetail)
    end
    if data.route ~= nil then
        ltassert(type(data.route) == 'boolean', 'route must be a boolean')
        SetBlipRoute(self.blip, data.route)
    end
    if data.routeColor ~= nil then
        ltassert(type(data.routeColor) == 'number', 'routeColor must be a number')
        SetBlipRouteColour(self.blip, data.routeColor)
    end
    if data.bright ~= nil then
        ltassert(type(data.bright) == 'boolean', 'bright must be a boolean')
        SetBlipBright(self.blip, data.bright)
    end
    if data.flash ~= nil then
        ltassert(type(data.flash) == 'boolean', 'flash must be a boolean')
        SetBlipFlashes(self.blip, data.flash)
        if data.flash then
            SetBlipFlashInterval(self.blip, data.flashInterval or 500)
        end
    end

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(self.blip)

    self.index = #blips + 1
    blips[self.index] = self

    return self
end

--- Gets all blips.
--- @return table Blips
--- @ltbridge export: GetAll
function GetAllBlips()
    return blips
end

--- Deletes all blips.
--- @ltbridge export: DeleteAll
function DeleteAllBlips()
    for i = 1, #blips do
        local blip = blips[i]
        if blip then
            blip:delete()
        end
    end
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- METHODS
-- ════════════════════════════════════════════════════════════════════════════════════════════

--- Deletes the blip.
function Blip:delete()
    if DoesBlipExist(self.blip) then
        RemoveBlip(self.blip)
        blips[self.index] = nil
    end
end

--- Sets the coordinates of the blip.
--- @param coords vector3 Coordinates to set
--- @return boolean
function Blip:setCoords(coords)
    ltassert(validateCoords(coords), 'coords must be a vector3')
    ltassert(self.type == 'coord', 'blip is not a coord blip')
    SetBlipCoords(self.blip, coords.x, coords.y, coords.z)
    return true
end

--- Sets the color of the blip.
--- @param color number Color to set
--- @return boolean
function Blip:setColor(color)
    ltassert(type(color) == 'number', 'color must be a number')
    SetBlipColour(self.blip, color)
    return true
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ════════════════════════════════════════════════════════════════════════════════════════════

OnResourceStop(function()
    DeleteAllBlips()
end)
