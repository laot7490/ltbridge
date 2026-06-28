local adapters = {
    ['es_extended'] = function(player, account, amount)
        if account == 'cash' then
            player.addMoney(amount)
        elseif account == 'bank' then
            player.addAccountMoney('bank', amount)
        elseif account == 'black' or account == 'black_money' then
            player.addAccountMoney('black_money', amount)
        end
    end,
    ['qb-core'] = function(player, account, amount)
        player.Functions.AddMoney(account, amount)
    end,
    ['qbx_core'] = function(player, account, amount)
        player.Functions.AddMoney(account, amount)
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Add money to player account.
--- @param source number Player source
--- @param account? string Money type (default: cash) (cash, bank, black_money, crypto etc.)
--- @param amount number Amount to add
--- @return boolean
function AddMoney(source, account, amount)
    ltassert(source, 'source is required')
    ltassert(amount, 'amount is required')
    ltassert(amount > 0, 'amount must be greater than 0')

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    adapter(player, account or 'cash', amount)
    return true
end
