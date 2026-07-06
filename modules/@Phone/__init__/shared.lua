local resourceName = nil

local list = {
    ['lb-phone'] = {},
    ['qb-phone'] = { providers = { 'lb-phone', 'gksphone', 'okokPhone', 'qs-smartphone-pro', 'yseries', 'cylex_phone' } },
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
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'Phone resource %s not found.', name)
    resourceName = name
end

local resource = DetectResource(list, 'phone')
if resource then
    SetPhoneResource(resource)
end
