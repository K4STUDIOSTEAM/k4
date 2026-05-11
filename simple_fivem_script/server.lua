-- Simple server-side command.
RegisterCommand('hello_server', function(source)
    local playerName = GetPlayerName(source) or 'player'
    TriggerClientEvent('simple_fivem_script:serverReply', source, 'Hi ' .. playerName .. ', your server script is running.')
end, false)
