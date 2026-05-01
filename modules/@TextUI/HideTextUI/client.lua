local exp = {}

local adapters = {
    ['ox_lib'] = function()
        exp:hideTextUI()
    end,
    ['lt-ui'] = function()
        exp:hideTextUI()
    end,
    ['jg-textui'] = function()
        exp:HideText()
    end,
    ['esx_textui'] = function()
        exp:HideUI()
    end,
    ['okokTextUI'] = function()
        exp:Close()
    end,
    ['cd_drawtextui'] = function()
        TriggerEvent('cd_drawtextui:HideUI')
    end,
    ['lation_ui'] = function()
        exp:hideText()
    end,
    ['lab-HintUI'] = function()
        exp:Hide()
    end,
}

--- Hides Text UI from screen.
--- @ltbridge export: Hide
function HideTextUI()
    local resource = GetTextUIResource()
    if not resource then return end

    exp = exports[resource]

    local adapter = adapters[resource]
    if adapter then
       adapter()
    end
end