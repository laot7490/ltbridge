local resourceName = nil

local list = {
    ['lb-phone'] = {},
    ['qb-phone'] = { providers = {'lb-phone', 'gksphone', 'okokPhone', 'qs-smartphone-pro', 'yseries', 'cylex_phone'} },
    ['okokPhone'] = {},
    ['qs-smartphone-pro'] = {},
    ['gksphone'] = {},
    ['cylex_phone'] = {},
}

--- Returns phone resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetPhoneResource()
    return resourceName
end

--- Force set phone resource. 
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetPhoneResource(name)
    if not name then return end
    if not list[name] then return printf('error', 'Phone resource ^3%s^7 not found.', name) end
    resourceName = name
end

local resource = DetectResource(list, 'phone')
if resource then
    SetPhoneResource(resource)
end