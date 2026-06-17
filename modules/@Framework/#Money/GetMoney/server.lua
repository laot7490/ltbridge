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
    return 0
end

--- Returns players money on account.
--- @param source number Player source
--- @param account string Money type (cash, bank, black_money, crypto etc.)
--- @return number amount
function GetMoney(source, account)
    if not source then
        printf('error', 'source is required')
        return 0
    end
    account = account or 'cash'

    local player = GetPlayer(source)
    if not player then
        printf('error', 'player not found')
        return 0
    end

    return adapter(player, account) or 0
end
