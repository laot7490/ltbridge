local adapters = {
    ['es_extended'] = function(player, account, amount)
        if account == 'cash' then
            player.removeMoney(amount)
        elseif account == 'bank' then
            player.removeAccountMoney('bank', amount)
        elseif account == 'black' or account == 'black_money' then
            player.removeAccountMoney('black_money', amount)
        end
    end,
    ['qb-core'] = function(player, account, amount)
        player.Functions.RemoveMoney(account, amount)
    end,
    ['qbx_core'] = function(player, account, amount)
        player.Functions.RemoveMoney(account, amount)
    end,
}

local adapter = adapters[GetFramework()] or function(...)
    printf('error', 'No supported framework found.')
    return false
end

--- Removes money from player account.
--- @param source number Player source
--- @param account? string Money type (default: cash) (cash, bank, black_money, crypto etc.)
--- @param amount number Amount to add
--- @return boolean `true` if success, `false` if anything goes wrong or player does not have that much money on account.
function RemoveMoney(source, account, amount)
    ltassert(source, 'source is required')
    ltassert(amount, 'amount is required')
    ltassert(amount > 0, 'amount must be greater than 0')

    account = account or 'cash'

    local player = GetPlayer(source)
    ltassert(player, 'player not found')

    local money = GetMoney(source, account)
    if money < amount then return false end

    adapter(player, account, amount)
    return true
end
