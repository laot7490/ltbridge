--- Creates a new OOP class.
--- @param name string Class name.
--- @param super? table Parent class to inherit from.
--- @return table
--- @ltbridge export: Create
function CreateClass(name, super)
    local cls = {}
    cls.__name = name
    cls.__index = cls
    cls.super = super

    if super then
        setmetatable(cls, { __index = super })
    end

    function cls.new(...)
        local instance = setmetatable({}, cls)
        instance.__destroyed = false
        
        if instance.constructor then
            instance:constructor(...)
        end
        return instance
    end

    function cls:include(mixin)
        for k, v in pairs(mixin) do
            if k ~= 'constructor' and k ~= '__index' and k ~= 'super' and k ~= '__name' then
                cls[k] = v
            end
        end
        return cls
    end

    function cls:isA(other)
        local current = self
        while current do
            if current == other then return true end
            
            local mt = getmetatable(current)
            if mt and mt.__index and mt.__index == other then return true end
            
            current = current.super
        end
        return false
    end

    local privateScope = setmetatable({}, { __mode = "k" })
    function cls:private()
        local p = privateScope[self]
        if not p then
            p = {}
            privateScope[self] = p
        end
        return p
    end

    function cls:destroy()
        if self.__destroyed then return end
        self.__destroyed = true
        
        if self.destructor then
            self:destructor()
        end
    end

    return cls
end