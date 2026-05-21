--- Send notification to player.
--- @param source number Player source
--- @param title? string Title
--- @param message string Messsage section
--- @param variant? 'success'|'error'|'info'|'warning' Type of notification.
--- @param length? number Duration in milliseconds. Defaults to 3500.
--- @ltbridge export: Send
function SendNotify(source, title, message, variant, length)
    TriggerClientEvent(__LT_RESOURCE_NAME..':client:@Notify:Send', source, title, message, variant, length)
end