local resourceName = nil

local list = {
    ['ox_lib'] = {},
    ['lt-ui'] = {},
    ['jg-textui'] = {},
    ['esx_textui'] = {},
    ['okokTextUI'] = {},
    ['cd_drawtextui'] = {},
    ['lation_ui'] = {},
    ['lab-HintUI'] = {},
}

--- Returns TextUI resource name.
--- @ltbridge return:list:nil
--- @ltbridge export: GetResource
function GetTextUIResource()
    return resourceName
end

--- Force set TextUI resource.
--- Useful for config assignment.
--- @ltbridge params:list:name
--- @ltbridge export: SetResource
function SetTextUIResource(name)
    ltassert(name and type(name) == 'string', 'name is required and must be a valid string')
    ltassert(list[name], 'TextUI resource %s not found.', name)
    resourceName = name
end

local resource = DetectResource(list, 'textui')
if resource then
    SetTextUIResource(resource)
end
