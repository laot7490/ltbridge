local adapters = {
    ['es_extended'] = function(player, account)
        if account == 'cash' then
            return player.getMoney()
        elseif account == 'bank' then
            return player.getAccount('bank').money
        elseif account == 'black' or account == 'black_money' then
            return player.getAccount('black_money').money
        end
    end,
    ['qb-core'] = function(player, account)
        return player.PlayerData.money[account] or 0
    end,
    ['qbx_core'] = function(player, account)
        return player.PlayerData.money[account] or 0
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return nil
end

--- Returns players money on account.
--- @param source number Player source
--- @param account? string Money type (default: cash) (cash, bank, black_money, crypto etc.)
--- @return number amount
function GetMoney(source, account)
    ltassert(source, 'source is required')

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    return adapter(player, account or 'cash') or 0
end
