local adapters = {
    ['lb-phone'] = function(source, mail, title, message)
        local number = exports["lb-phone"]:GetEquippedPhoneNumber(source)
        if not number then return false end
        local sourceMail = exports["lb-phone"]:GetEmailAddress(number)
        if not sourceMail then return false end
        local success, id = exports["lb-phone"]:SendMail({
            to = sourceMail,
            sender = mail,
            subject = title,
            message = message,
        })
        return success or false
    end,
    ['qb-phone'] = function(source, mail, title, message)
        local cId = GetPlayerCitizenId(source)
        if not cId then return false end

        local mailData = { sender = mail, subject = title, message = message }
        exports["qb-phone"]:sendNewMailToOffline(cId, mailData)
        return true
    end,
    ['okokPhone'] = function(source, mail, title, message)
        local senderAddress = exports.okokPhone:getEmailAddressFromSource(source)
        if not senderAddress then return false end

        local data = {
            sender = senderAddress,
            recipients = { mail },
            subject = title,
            body = message,
        }

        local success = exports.okokPhone:sendEmail(data)
        return success or false
    end,
    ['qs-smartphone-pro'] = function(source, mail, title, message)
        exports['qs-smartphone-pro']:sendNewMail(source, {
            sender = mail,
            subject = title,
            message = message
        })
        return true
    end,
    ['gksphone'] = function(source, mail, title, message)
        exports["gksphone"]:SendNewMail(source, {
            sender = mail,
            image = '/html/img/icons/mail.png',
            subject = title,
            message = message,
        })
        return true
    end,
    ['cylex_phone'] = function(source, mail, title, message)
        local identifier = GetPlayerCitizenId(source)
        if not identifier then return false end
        exports['cylex_phone']:sendMail(identifier, source, { sender = mail, subject = title, message = message })
        return true
    end
}

--- Send mail to player.
--- @param source number Player source
--- @param mail string Sender mail
--- @param title string Mail title
--- @param message string Content of mail
--- @return boolean
function SendMail(source, mail, title, message)
    if not source then return false end
    local adapter = adapters[GetPhoneResource()]
    return adapter(source, mail, title, message) or false
end

RegisterNetEvent(LT_RESOURCE_NAME..':server:@Phone:Send', function(mail, title, message)
    local src = source
    SendMail(src, mail, title, message)
end)