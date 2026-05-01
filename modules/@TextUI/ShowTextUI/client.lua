local exp = {}

local adapters = {
    ['ox_lib'] = function(text)
        exp:showTextUI(text)
    end,
    ['lt-ui'] = function(text)
        exp:showTextUI(text)
    end,
    ['jg-textui'] = function(text)
        exp:DrawText(text)
    end,
    ['esx_textui'] = function(text)
        exp:TextUI(text)
    end,
    ['okokTextUI'] = function(text)
        exp:Open(text, 'darkblue', 'right', false)
    end,
    ['cd_drawtextui'] = function(text)
        TriggerEvent('cd_drawtextui:ShowUI', 'show', text)
    end,
    ['lation_ui'] = function(text)
        exp:showText({description = text, position = 'right-center'})
    end,
    ['lab-HintUI'] = function(text)
        exp:Show(text, 'Hint')
    end,
}

--- Show Text UI on screen.
--- @param text string Text to show on screen.
--- @ltbridge export: Show
function ShowTextUI(text)
    local resource = GetTextUIResource()
    if not resource then return end

    exp = exports[resource]

    local adapter = adapters[resource]
    if adapter then
       adapter(tostring(text))
    end
end