--- Returns players money on account.
--- @param source number Player source
--- @param account string Money type (cash, bank, black_money, crypto etc.)
--- @return number amount
function GetMoney(source, account)
    if not source then return 0 end
    account = account or 'cash'

    local Player = GetPlayer(source)
    if not Player then return 0 end
    
    if ESX then
        if account == 'cash' then
            return Player.getMoney()
        elseif account == 'bank' then
            return Player.getAccount('bank').money
        elseif account == 'black' or account == 'black_money' then
            return Player.getAccount('black_money').money
        end
    elseif QBX or QBCore then
        return Player.PlayerData.money[account] or 0
    end
    
    return 0
end