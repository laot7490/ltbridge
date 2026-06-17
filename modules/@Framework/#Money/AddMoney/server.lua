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
--- @param account string Money type (cash, bank, black_money, crypto etc.)
--- @param amount number Amount to add
--- @return boolean
function AddMoney(source, account, amount)
    if not source or not amount or amount <= 0 then
        printf('error', 'source, amount and account are required and amount must be greater than 0')
        return false
    end
    account = account or 'cash'

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return false
    end

    adapter(player, account, amount)
    return true
end
