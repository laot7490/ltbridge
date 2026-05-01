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
    if not name then return end
    if not list[name] then return printf('error', 'TextUI resource ^3%s^7 not found.', name) end
    resourceName = name
end

local resource = DetectResource(list, 'textui')
if resource then
    SetTextUIResource(resource)
end