local isCuffed = false
local isEscorted = false
local escortOfficerServerId = nil

local function notify(message)
    if lib and lib.notify then
        lib.notify({
            title = 'Police System',
            description = message,
            type = 'inform'
        })
        return
    end

    TriggerEvent('chat:addMessage', {
        color = { 0, 180, 255 },
        args = { '[Police System]', message }
    })
end

local function getClosestPlayerServerId(maxDistance)
    local myPed = PlayerPedId()
    local myCoords = GetEntityCoords(myPed)
    local players = GetActivePlayers()

    local closestServerId = nil
    local closestDistance = maxDistance + 0.001

    for _, player in ipairs(players) do
        local targetPed = GetPlayerPed(player)
        if targetPed ~= myPed then
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(myCoords - targetCoords)
            if distance < closestDistance then
                closestDistance = distance
                closestServerId = GetPlayerServerId(player)
            end
        end
    end

    return closestServerId, closestDistance
end

local function forceDetainAnimation()
    local ped = PlayerPedId()
    if IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3) then
        return
    end

    RequestAnimDict('mp_arresting')
    while not HasAnimDictLoaded('mp_arresting') do
        Wait(0)
    end

    TaskPlayAnim(ped, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0.0, false, false, false)
end

CreateThread(function()
    while true do
        if isCuffed then
            Wait(0)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 45, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)

            local ped = PlayerPedId()
            if not IsEntityDead(ped) then
                SetEnableHandcuffs(ped, true)
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
                forceDetainAnimation()
            end
        else
            Wait(250)
        end
    end
end)

CreateThread(function()
    while true do
        if isEscorted and escortOfficerServerId then
            Wait(250)
            local officerPlayer = GetPlayerFromServerId(escortOfficerServerId)
            if officerPlayer ~= -1 then
                local myPed = PlayerPedId()
                local officerPed = GetPlayerPed(officerPlayer)

                if officerPed ~= 0 and DoesEntityExist(officerPed) then
                    if not IsEntityAttachedToEntity(myPed, officerPed) then
                        AttachEntityToEntity(myPed, officerPed, 11816, 0.45, 0.45, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                    end
                end
            end
        else
            Wait(400)
        end
    end
end)

RegisterNetEvent('k4_police:notify', function(message)
    notify(message)
end)

RegisterNetEvent('k4_police:setCuffed', function(state)
    local ped = PlayerPedId()
    isCuffed = state == true

    if not isCuffed then
        ClearPedTasksImmediately(ped)
        SetEnableHandcuffs(ped, false)
    end
end)

RegisterNetEvent('k4_police:setEscorted', function(state, officerServerId)
    local ped = PlayerPedId()

    isEscorted = state == true
    escortOfficerServerId = officerServerId

    if not isEscorted then
        DetachEntity(ped, true, false)
        escortOfficerServerId = nil
    end
end)

RegisterNetEvent('k4_police:putInNearestVehicle', function()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)

    if vehicle ~= 0 then
        for i = 0, GetVehicleMaxNumberOfPassengers(vehicle) do
            if IsVehicleSeatFree(vehicle, i) then
                TaskWarpPedIntoVehicle(ped, vehicle, i)
                return
            end
        end
    end
end)

RegisterNetEvent('k4_police:removeFromVehicle', function()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        TaskLeaveVehicle(ped, GetVehiclePedIsIn(ped, false), 16)
    end
end)

RegisterNetEvent('k4_police:sendToJail', function(coords, minutes, reason)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)

    local text = ('You are jailed for %s minute(s).'):format(minutes)
    if reason and reason ~= '' then
        text = text .. ' Reason: ' .. reason
    end

    notify(text)
end)

RegisterNetEvent('k4_police:releaseFromJail', function(coords)
    local ped = PlayerPedId()
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    notify('You have been released from jail.')
end)

RegisterNetEvent('k4_police:dispatch911', function(callerName, message, coords)
    notify(('911 | %s: %s'):format(callerName, message))

    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, Config.DispatchBlipSprite)
    SetBlipColour(blip, Config.DispatchBlipColor)
    SetBlipScale(blip, Config.DispatchBlipScale)
    SetBlipAsShortRange(blip, false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('911 Caller')
    EndTextCommandSetBlipName(blip)

    SetTimeout(Config.DispatchBlipDurationMs, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end)

RegisterCommand('duty', function()
    TriggerServerEvent('k4_police:toggleDuty')
end, false)

RegisterCommand('cuff', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:cuff', target)
end, false)

RegisterCommand('uncuff', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:uncuff', target)
end, false)

RegisterCommand('escort', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:escort', target)
end, false)

RegisterCommand('putinveh', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:putInVehicle', target)
end, false)

RegisterCommand('removefromveh', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:removeFromVehicle', target)
end, false)

RegisterCommand('search', function()
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:search', target)
end, false)

RegisterCommand('fine', function(_, args)
    local amount = tonumber(args[1])
    if not amount then
        notify('Usage: /fine [amount] [reason]')
        return
    end

    local reason = table.concat(args, ' ', 2)
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:fine', target, amount, reason)
end, false)

RegisterCommand('jail', function(_, args)
    local minutes = tonumber(args[1])
    if not minutes then
        notify('Usage: /jail [minutes] [reason]')
        return
    end

    local reason = table.concat(args, ' ', 2)
    local target, dist = getClosestPlayerServerId(Config.InteractDistance)
    if not target then
        notify(('No player within %.1f meters.'):format(Config.InteractDistance))
        return
    end

    TriggerServerEvent('k4_police:jail', target, minutes, reason)
end, false)

RegisterCommand('unjail', function(_, args)
    local target = tonumber(args[1])
    if not target then
        notify('Usage: /unjail [serverId]')
        return
    end

    TriggerServerEvent('k4_police:unjail', target)
end, false)

RegisterCommand('911', function(_, args)
    local message = table.concat(args, ' ')
    if message == '' then
        notify('Usage: /911 [message]')
        return
    end

    TriggerServerEvent('k4_police:call911', message)
end, false)
