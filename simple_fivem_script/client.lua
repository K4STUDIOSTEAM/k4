-- Simple local client command.
RegisterCommand('hello', function()
    TriggerEvent('chat:addMessage', {
        color = { 0, 255, 150 },
        args = { '[Simple Script]', 'Hello from the client script!' }
    })
end, false)

-- Message from server example.
RegisterNetEvent('simple_fivem_script:serverReply', function(msg)
    TriggerEvent('chat:addMessage', {
        color = { 255, 200, 0 },
        args = { '[Server]', msg }
    })
end)
