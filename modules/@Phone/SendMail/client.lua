--- Send mail to player. Recommend to use `server` side function.
--- @param mail string Sender mail
--- @param title string Mail title
--- @param message string Content of mail
--- @return boolean
--- @ltbridge export: SendMail
function SendMail(mail, title, message)
    TriggerServerEvent(LT_RESOURCE_NAME..':server:@Phone:Send', mail, title, message)
    return true
end