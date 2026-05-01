--- Removes money from player account.
--- @param source number Player source
--- @param account string Money type (cash, bank, black_money, crypto etc.)
--- @param amount number Amount to add
--- @return boolean `true` if success, `false` if anything goes wrong or player does not have that much money on account.
function RemoveMoney(source, account, amount)
    if not source or not amount or amount <= 0 then return false end
    account = account or 'cash'

    local Player = GetPlayer(source)
    if not Player then return false end

    local money = GetMoney(source, account)
    if money < amount then return false end

    if ESX then
        if account == 'cash' then
            Player.removeMoney(amount)
        elseif account == 'bank' then
            Player.removeAccountMoney('bank', amount)
        elseif account == 'black' or account == 'black_money' then
            Player.removeAccountMoney('black_money', amount)
        end
        return true
    elseif QBX or QBCore then
        return Player.Functions.RemoveMoney(account, amount, 'LTBridge')
    end
    
    return false
end