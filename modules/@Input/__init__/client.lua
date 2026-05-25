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
    if not name then return end
    if not list[name] then return printf('error', 'Input resource ^3%s^7 not found.', name) end
    resourceName = name
end

local resource = DetectResource(list, 'input')
if resource then
    SetInputResource(resource)
end

-- ════════════════════════════════════════════════════════════════════════════════════════════
-- HELPERS
-- ════════════════════════════════════════════════════════════════════════════════════════════

-- QB to OX
local function convertTypesQBtoOX(_type)
    if _type == "text" then
        return "input"
    elseif _type == "password" then
        return "input"
    elseif _type == "number" then
        return "number"
    elseif _type == "radio" then
        return "checkbox"
    elseif _type == "checkbox" then
        return "checkbox"
    elseif _type == "select" then
        return "select"
    end
end

local function convertInputQBtoOX(inputs)
    local returnData = {}
    for i, v in pairs(inputs) do
        local input = {
            label = v.text,
            name = i,
            type = convertTypesQBtoOX(v.type),
            required = v.isRequired,
            default = v.placeholder,
        }
        if v.type == "select" then
            input.options = {}
            for i, v in pairs(v.options) do
                table.insert(input.options, {value = v.value, label = v.text})
            end
        elseif v.type == "checkbox" then
            for i, v in pairs(v.options) do
                table.insert(returnData, {value = v.value, label = v.text})
            end
        end
        table.insert(returnData, input)
    end
    return returnData
end

-- OX to QB
local function convertTypesOXtoQB(_type)
    if _type == "input" then
        return "text"
    elseif _type == "number" then
        return "number"
    elseif _type == "checkbox" then
        return "checkbox"
    elseif _type == "select" then
        return "select"
    elseif _type == "multi-select" then
        return "select"
    elseif _type == "slider" then
        return "number"
    elseif _type == "color" then
        return "text"
    elseif _type == "date" then
        return "date"
    elseif _type == "date-range" then
        return "date"
    elseif _type == "time" then
        return "time"
    elseif _type == "textarea" then
        return "text"
    end
end

local function convertInputOXtoQB(inputs)
    local returnData = {}
    for i, v in pairs(inputs) do
        local input = {
            text = v.label,
            name = i,
            type = convertTypesOXtoQB(v.type),
            isRequired = v.required,
            default = v.default or "",
        }
        if v.type == "select" then
            input.text = ""
            input.options = {}
            for k, j in pairs(v.options) do
                table.insert(input.options, {value = j.value, text = j.label})
            end
        elseif v.type == "checkbox" then
            input.text = ""
            input.options = {}
            if v.options then -- Checks if options varible is valid so checkboxes are bundled together (not used by ox for each checkpoint)
                for k, j in pairs(v.options) do
                    table.insert(input.options, {value = #returnData + #input.options + 1, text = j.label, checked = j.checked}) -- added checked option (used to show box as ticked or not)
                end
            else -- If options is not valid or people pass a single checkbox then it will be a single checkbox per entry
                table.insert(input.options, {value = #returnData + 1, text = v.label, checked = v.checked}) -- Kept value just incase it's used for other stuffs
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
        local inputs = data.inputs
        if isQB then
            local convertedData = {}
            local returnData = exports['ox_lib']:inputDialog(title, convertInputQBtoOX(inputs))
            for i, v in pairs(inputs) do
                for k, j in pairs(returnData or {}) do
                    if k == v.name then
                        convertedData[v.name] = j
                    end
                end
            end
            return convertedData
        else
            return exports['ox_lib']:inputDialog(title, data)
        end
    end,
    ['lt-ui'] = function(title, data, isQB, submitText)
        local inputs = data.inputs
        if isQB then
            local convertedData = {}
            local returnData = exports['lt-ui']:inputDialog(title, convertInputQBtoOX(inputs))
            for i, v in pairs(inputs) do
                for k, j in pairs(returnData or {}) do
                    if k == v.name then
                        convertedData[v.name] = j
                    end
                end
            end
            return convertedData
        else
            return exports['lt-ui']:inputDialog(title, data)
        end
    end,
    ['qb-input'] = function(title, data, isQB, submitText)
        local input = data.inputs
        if not isQB then
            input = convertInputOXtoQB(data)
        end
        local returnData = exports['qb-input']:ShowInput({
            header = title,
            submitText = submitText or "Submit",
            inputs = input
        })
        if not returnData then return end
        if returnData[1] then return returnData end
        local convertedData = {}
        if isQB then
            for i, v in pairs(input) do
                for k, j in pairs(returnData) do
                    if k == v.name then
                        convertedData[v.name] = j
                    end
                end
            end
            return convertedData
        end

        for i, v in pairs(returnData) do
            local index = i and tonumber(i)
            v = tostring(v) == "true" and true or (tostring(v) == "false" and false or v)
            if not index then
                table.insert(convertedData, v)
            else
                convertedData[index] = v
            end
        end
        return convertedData
    end,
    ['lation_ui'] = function(title, data, isQB, submitText)
        local inputs = data.inputs
        if isQB then
            return exports.lation_ui:input({title = title, inputs = convertInputQBtoOX(inputs)})
        else
            return exports.lation_ui:input({title = title, options = data})
        end
    end,
}

--- Opens a input dialog.
--- @param header string Title of input dialog
--- @param data table Data table
--- @param isQB? boolean If data table is sent with QB format set to true, default: false
--- @param submitText? string Submit button text, only for `qb-input`
--- @return table|nil
--- @ltbridge export: Open
function OpenInput(header, data, isQB, submitText)
    local resource = GetInputResource()
    if not resource then return end
    local adapter = adapters[resource]
    if not adapter then printf('error', 'Input resource not found. This function will return nil.') return end
    return adapter(header, data, isQB, submitText)
end