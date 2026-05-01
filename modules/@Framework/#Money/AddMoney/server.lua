--- Add money to player account.
--- @param source number Player source
--- @param account string Money type (cash, bank, black_money, crypto etc.)
--- @param amount number Amount to add
--- @return boolean
function AddMoney(source, account, amount)
    if not source or not amount or amount <= 0 then return false end
    account = account or 'cash'

    local Player = GetPlayer(source)
    if not Player then return false end
    
    if ESX then
        if account == 'cash' then
            Player.addMoney(amount)
        elseif account == 'bank' then
            Player.addAccountMoney('bank', amount)
        elseif account == 'black' or account == 'black_money' then
            Player.addAccountMoney('black_money', amount)
        end
        return true
    elseif QBX or QBCore then
        return Player.Functions.AddMoney(account, amount)
    end
    
    return false
end