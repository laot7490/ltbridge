local currentLocale = nil
local dict = {}
local corruptedMsg <const> = 'Locale file ^3%s^7 is corrupted.'

local function unflattenDict(flat)
    local result = {}

    for key, value in pairs(flat) do
        local current = result
        local parts = {}

        for part in key:gmatch("[^%.]+") do
            table.insert(parts, part)
        end

        for i = 1, #parts do
            local part = parts[i]

            if i == #parts then
                current[part] = value
            else
                current[part] = current[part] or {}
                current = current[part]
            end
        end
    end

    return result
end

---@param source { [string]: string }
---@param target { [string]: string }
---@param prefix? string
local function flattenDict(source, target, prefix)
    for key, value in pairs(source) do
        local fullKey = prefix and (prefix .. '.' .. key) or key

        if type(value) == 'table' then
            flattenDict(value, target, fullKey)
        else
            target[fullKey] = value
        end
    end

    return target
end

--- Load and prepare localization from `locales` folder of resource.
--- Don't forget to add `locales/*.{json,lua}` to `files` in `fxmanifest.lua`
---
--- **JSON**:
--- ```lua
--- LT.Locale.Init('en', 'json') -- Setup a JSON locale.
---
--- -- locales/en.json
--- ```
--- ```JSON
--- {
---     "client": {
---         "hello": "Hello!",
---         "how_are_you": "How are you, %s?",
---         "hello_how_are_you": "${client.hello} ${client.how_are_you}"
---     }
--- }
--- ```
---
--- **LUA**:
--- ```lua
--- LT.Locale.Init('en', 'lua') -- Setup a LUA locale.
--- 
--- -- locales/en.lua
--- return {
---     client = {
---         hello = 'Hello!',
---         how_are_you = 'How are you, %s?',
---         hello_how_are_you = '${client.hello} ${client.how_are_you}'
---     },
--- }
--- ```
--- **Using the locales:**
---
--- ```lua
--- local _t = LT.Locale.Get -- Simplify the function.
---
--- _t('client.hello') -> Hello!
--- _t('client.how_are_you', 'John') -> How are you, John?
--- _t('client.hello_how_are_you', 'John') -> Hello! How are you, John?
--- ```
--- @param key string Locale key (e.g. 'en', 'tr')
--- @param fileType? 'json'|'lua' Default: `json`
--- @ltbridge export: Init
function InitLocale(key, fileType)
    local extension = fileType == 'lua' and 'lua' or 'json'

    -- JSON
    local locales = nil
    local file = LoadResourceFile(__LT_RESOURCE_NAME, ('locales/%s.%s'):format(key, extension))

    -- Try english fallback.
    if not file then
        file = LoadResourceFile(__LT_RESOURCE_NAME, ('locales/en.%s'):format(extension))
        if not file then
            printf('error', 'Locale file ^3%s^7 and fallback ^3en^7 not found or cannot be loaded. Stopping initialization.', key)
            return
        end

        printf('error', 'Locale file ^3%s^7 not found or cannot be loaded. Using ^3en^7 fallback.', key)
        key = 'en'
    end

    if extension == 'json' then
        locales = json.decode(file)
    else
        local fn, err = load(file, ('@@%s/locales/%s.lua'):format(__LT_RESOURCE_NAME, key))
        if not fn then
            printf('error', '%s\n^1%s^7\n', corruptedMsg, key, err)
            return
        end
        locales = fn()
    end

    if not locales or type(locales) ~= 'table' then
        printf('error', corruptedMsg, key)
        return
    end

    local flat = flattenDict(locales, {})
    for k, v in pairs(flat) do
        if type(v) == 'string' then
            for var in v:gmatch('${[%w%s%p]-}') do
                local locale = flat[var:sub(3, -2)]

                if locale then
                    locale = locale:gsub('%%', '%%%%')
                    v = v:gsub(var, locale)
                end
            end
        end

        dict[k] = v
    end
    currentLocale = key
end

--- Get localized string with formatting.
--- @param str string Locale key.
--- @param ...? any Format parameters (Optional)
--- ```lua
--- -- Simplify the function.
--- local _t = LT.Locale.Get
--- 
--- _t('client.hello') -> Hello.
--- _t('client.hello_name', 'John') -> Hello, John.
--- ```
--- @return string
--- @ltbridge export: Get
function GetString(str, ...)
    local txt = dict[str]

    if txt then
        if ... then
            return txt and txt:format(...)
        end

        return txt
    end

    return str
end

--- Returns all translated strings as a table.
--- Useful for sending translations to NUI.
---
--- By default, the dictionary is flattened:
--- Nested keys like `client -> hello` become a single key (`"client.hello"`).
---
--- If `keepNesting` is set to `true`, the original nested structure is preserved:
--- `{ client = { hello = "..." } }`
---
---@param keepNesting? boolean Whether to preserve the original nested structure
---@return table<string, string|table> `Translated strings`
---@ltbridge export: GetAllStrings
function GetLocaleStrings(keepNesting)
    local returnDict = dict or {}
    return keepNesting and unflattenDict(returnDict) or returnDict
end

--- Returns the current locale key.
--- @return string?
--- @ltbridge export: GetCurrentKey
function GetCurrentLocaleKey()
    if not currentLocale then
        printf('error', 'No locale has been initialized. Please call `LT.Locale.Init` first.')
        return
    end

    return currentLocale
end