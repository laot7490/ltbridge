local resourceName = nil

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['qb-input'] = {},
    ['lation_ui'] = {},
}

--- Returns input resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetInputResource()
    return resourceName
end

--- Force set input resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetInputResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Input resource %s not found.', name)
    resourceName = name
end

local resource = DetectResource(list, 'input')
if resource then
    SetInputResource(resource)
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════════════════

local function coerceBool(value)
    if value == 'true' then return true end
    if value == 'false' then return false end
    return value
end

local function resolveInputs(data, isQB)
    if not data then return nil end
    if isQB then
        if not data.inputs then
            printf('warning', 'Input dialog (QB format) requires data.inputs.')
            return nil
        end
        return data.inputs
    end
    if data.inputs then
        return data.inputs
    end
    return data
end

--- Maps dialog return values by field name; keeps extra keys (e.g. qb-input checkbox option.value).
local function mapNamedReturn(returnData, fields, coerceValues)
    if not returnData then return nil end
    local convertedData = {}
    for _, field in ipairs(fields) do
        local name = field.name
        if name and returnData[name] ~= nil then
            convertedData[name] = coerceValues and coerceBool(returnData[name]) or returnData[name]
        end
    end
    for key, value in pairs(returnData) do
        if convertedData[key] == nil then
            convertedData[key] = coerceValues and coerceBool(value) or value
        end
    end
    return convertedData
end

local function isSequentialArray(tbl)
    if type(tbl) ~= 'table' or tbl[1] == nil then return false end
    for k in pairs(tbl) do
        if type(k) ~= 'number' then return false end
    end
    return true
end

--- Normalizes qb-input / ox-style returns when not using QB field names directly.
local function convertOxReturn(returnData)
    if not returnData then return nil end
    if isSequentialArray(returnData) then
        local convertedData = {}
        for i, v in ipairs(returnData) do
            convertedData[i] = coerceBool(v)
        end
        return convertedData
    end
    local hasStringKey = false
    for k in pairs(returnData) do
        if type(k) == 'string' then
            hasStringKey = true
            break
        end
    end
    if hasStringKey then
        local convertedData = {}
        for key, value in pairs(returnData) do
            convertedData[key] = coerceBool(value)
        end
        return convertedData
    end
    local convertedData = {}
    for key, value in pairs(returnData) do
        local index = tonumber(key)
        convertedData[index or key] = coerceBool(value)
    end
    return convertedData
end

local function buildOxOptions(options)
    local oxOptions = {}
    for _, option in ipairs(options or {}) do
        table.insert(oxOptions, {
            value = option.value,
            label = option.text or option.label,
            checked = option.checked,
        })
    end
    return oxOptions
end

local function buildQbOptions(options)
    local qbOptions = {}
    for _, option in ipairs(options or {}) do
        table.insert(qbOptions, {
            value = option.value,
            text = option.text or option.label,
            checked = option.checked,
        })
    end
    return qbOptions
end

-- QB to OX
local function convertTypesQBtoOX(_type)
    if _type == 'text' then
        return 'input'
    elseif _type == 'password' then
        return 'input'
    elseif _type == 'number' then
        return 'number'
    elseif _type == 'radio' then
        return 'select'
    elseif _type == 'checkbox' then
        return 'checkbox'
    elseif _type == 'select' then
        return 'select'
    elseif _type == 'color' then
        return 'color'
    end
    return 'input'
end

local function convertInputQBtoOX(inputs)
    local returnData = {}
    for i, v in ipairs(inputs) do
        local fieldName = v.name or tostring(i)
        if not v.name then
            printf('warning', 'QB input field at index ^3%d^7 is missing ^3name^7.', i)
        end
        local input = {
            label = v.text,
            name = fieldName,
            type = convertTypesQBtoOX(v.type or 'text'),
            required = v.isRequired,
            default = v.default or v.placeholder,
        }
        if v.type == 'password' then
            input.password = true
        end
        if v.type == 'select' or v.type == 'radio' or v.type == 'checkbox' then
            input.options = buildOxOptions(v.options)
        end
        table.insert(returnData, input)
    end
    return returnData
end

-- OX to QB
local function convertTypesOXtoQB(_type, field)
    if _type == 'input' then
        if field and field.password then
            return 'password'
        end
        return 'text'
    elseif _type == 'number' then
        return 'number'
    elseif _type == 'checkbox' then
        return 'checkbox'
    elseif _type == 'select' or _type == 'multi-select' then
        return 'select'
    elseif _type == 'slider' then
        return 'number'
    elseif _type == 'color' then
        return 'color'
    elseif _type == 'date' or _type == 'date-range' or _type == 'time' or _type == 'textarea' then
        return 'text'
    end
    return 'text'
end

local function convertInputOXtoQB(inputs)
    local returnData = {}
    for i, v in ipairs(inputs) do
        local fieldName = v.name or tostring(i)
        if not v.name then
            printf('warning', 'OX input field at index ^3%d^7 is missing ^3name^7.', i)
        end
        local input = {
            text = v.label or v.text or '',
            name = fieldName,
            type = convertTypesOXtoQB(v.type, v),
            isRequired = v.required,
            default = v.default or '',
        }
        if v.type == 'select' or v.type == 'multi-select' then
            input.options = buildQbOptions(v.options)
        elseif v.type == 'checkbox' then
            input.options = {}
            if v.options then
                for _, option in ipairs(v.options) do
                    table.insert(input.options, {
                        value = option.value or option.name,
                        text = option.label or option.text,
                        checked = option.checked,
                    })
                end
            else
                table.insert(input.options, {
                    value = fieldName,
                    text = v.label or v.text or fieldName,
                    checked = v.checked,
                })
            end
        end
        table.insert(returnData, input)
    end
    return returnData
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- FUNCTION
-- ════════════════════════════════════════════════════════════════════════════════════════════

local adapters = {
    ['ox_lib'] = function(title, data, isQB, submitText)
        local inputs = resolveInputs(data, isQB)
        if not inputs then return end
        if isQB then
            local returnData = exports['ox_lib']:inputDialog(title, convertInputQBtoOX(inputs))
            return mapNamedReturn(returnData, inputs, false)
        end
        return exports['ox_lib']:inputDialog(title, inputs)
    end,
    ['lt-ui'] = function(title, data, isQB, submitText)
        local inputs = resolveInputs(data, isQB)
        if not inputs then return end
        if isQB then
            local returnData = exports['lt-ui']:inputDialog(title, convertInputQBtoOX(inputs))
            return mapNamedReturn(returnData, inputs, false)
        end
        return exports['lt-ui']:inputDialog(title, inputs)
    end,
    ['qb-input'] = function(title, data, isQB, submitText)
        local inputs = resolveInputs(data, isQB)
        if not inputs then return end
        if not isQB then
            inputs = convertInputOXtoQB(inputs)
        end
        local returnData = exports['qb-input']:ShowInput({
            header = title or data.header,
            submitText = submitText or data.submitText or 'Submit',
            inputs = inputs,
        })
        if not returnData then return end
        if isQB then
            return mapNamedReturn(returnData, inputs, true)
        end
        return convertOxReturn(returnData)
    end,
    ['lation_ui'] = function(title, data, isQB, submitText)
        local inputs = resolveInputs(data, isQB)
        if not inputs then return end
        if isQB then
            local returnData = exports.lation_ui:input({ title = title, inputs = convertInputQBtoOX(inputs) })
            return mapNamedReturn(returnData, inputs, false)
        end
        return exports.lation_ui:input({ title = title, options = inputs })
    end,
}

--- Opens a input dialog.
--- @param header string Title of input dialog
--- @param data table Data table (`{ inputs = ... }` for QB; ox field array or `{ inputs = ... }` otherwise)
--- @param isQB? boolean If data table is sent with QB format set to true, default: false
--- @param submitText? string Submit button text, only for `qb-input`
--- @return table|nil
--- @ltbridge export: Open
function OpenInput(header, data, isQB, submitText)
    local resource = GetInputResource()
    ltassert(resource, 'input resource not found.')
    local adapter = adapters[resource]
    return adapter(header, data, isQB, submitText)
end
