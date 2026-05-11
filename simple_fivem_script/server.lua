local onDuty = {}
local cuffed = {}
local escortedBy = {}
local jailedUntil = {}

local function notify(src, message)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Police System',
        description = message,
        type = 'inform'
    })

    -- Fallback for clients without ox_lib loaded for any reason.
    TriggerClientEvent('k4_police:notify', src, message)
end

local function hasIdentifierPermission(src)
    if not Config.PoliceIdentifiers or #Config.PoliceIdentifiers == 0 then
        return false
    end

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local playerIdentifier = GetPlayerIdentifier(src, i)
        for _, allowed in ipairs(Config.PoliceIdentifiers) do
            if playerIdentifier == allowed then
                return true
            end
        end
    end

    return false
end

local function isPolice(src)
    if src <= 0 then
        return true
    end

    if IsPlayerAceAllowed(src, Config.AcePermission) then
        return true
    end

    return hasIdentifierPermission(src)
end

local function canUsePoliceActions(src)
    if not isPolice(src) then
        notify(src, 'You do not have police permission.')
        return false
    end

    if Config.RequireDutyForActions and not onDuty[src] then
        notify(src, 'You must be on duty. Use /duty.')
        return false
    end

    return true
end

local function isPlayerNearby(src, target)
    local srcPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if srcPed <= 0 or targetPed <= 0 then
        return false
    end

    local srcCoords = GetEntityCoords(srcPed)
    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(srcCoords - targetCoords)

    return distance <= Config.InteractDistance + 0.2
end

local function releasePlayerFromJail(target, actor)
    jailedUntil[target] = nil
    TriggerClientEvent('k4_police:releaseFromJail', target, Config.JailReleasePosition)

    if actor and actor > 0 then
        local targetName = GetPlayerName(target) or ('ID %s'):format(target)
        notify(actor, ('Released %s from jail.'):format(targetName))
    end

    notify(target, 'You are no longer jailed.')
end

CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        for playerId, releaseAt in pairs(jailedUntil) do
            if now >= releaseAt then
                releasePlayerFromJail(playerId, nil)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    onDuty[src] = nil
    cuffed[src] = nil
    escortedBy[src] = nil
    jailedUntil[src] = nil

    for target, officer in pairs(escortedBy) do
        if officer == src then
            escortedBy[target] = nil
            TriggerClientEvent('k4_police:setEscorted', target, false, nil)
        end
    end
end)

RegisterNetEvent('k4_police:toggleDuty', function()
    local src = source
    if not isPolice(src) then
        notify(src, 'You do not have police permission.')
        return
    end

    onDuty[src] = not onDuty[src]
    notify(src, onDuty[src] and 'You are now on duty.' or 'You are now off duty.')
end)

RegisterNetEvent('k4_police:cuff', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    cuffed[target] = true
    TriggerClientEvent('k4_police:setCuffed', target, true)
    notify(src, ('Cuffed %s.'):format(GetPlayerName(target) or target))
    notify(target, 'You were cuffed by police.')
end)

RegisterNetEvent('k4_police:uncuff', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    cuffed[target] = nil
    escortedBy[target] = nil
    TriggerClientEvent('k4_police:setEscorted', target, false, nil)
    TriggerClientEvent('k4_police:setCuffed', target, false)
    notify(src, ('Uncuffed %s.'):format(GetPlayerName(target) or target))
    notify(target, 'You were uncuffed by police.')
end)

RegisterNetEvent('k4_police:escort', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    if not cuffed[target] then
        notify(src, 'Target must be cuffed first.')
        return
    end

    if escortedBy[target] == src then
        escortedBy[target] = nil
        TriggerClientEvent('k4_police:setEscorted', target, false, nil)
        notify(src, ('Stopped escorting %s.'):format(GetPlayerName(target) or target))
        notify(target, 'You are no longer escorted.')
        return
    end

    escortedBy[target] = src
    TriggerClientEvent('k4_police:setEscorted', target, true, src)
    notify(src, ('Now escorting %s.'):format(GetPlayerName(target) or target))
    notify(target, 'You are being escorted.')
end)

RegisterNetEvent('k4_police:putInVehicle', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not cuffed[target] then
        notify(src, 'Target must be cuffed first.')
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    TriggerClientEvent('k4_police:putInNearestVehicle', target)
    notify(src, ('Placed %s in vehicle.'):format(GetPlayerName(target) or target))
end)

RegisterNetEvent('k4_police:removeFromVehicle', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    TriggerClientEvent('k4_police:removeFromVehicle', target)
    notify(src, ('Removed %s from vehicle.'):format(GetPlayerName(target) or target))
end)

RegisterNetEvent('k4_police:search', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    -- Framework integrations (ESX/QBCore/OX) can be plugged in here.
    notify(src, ('Searched %s (standalone placeholder).'):format(GetPlayerName(target) or target))
    notify(target, 'A police officer searched you.')
end)

RegisterNetEvent('k4_police:fine', function(target, amount, reason)
    local src = source
    target = tonumber(target)
    amount = math.floor(tonumber(amount) or 0)
    reason = tostring(reason or '')

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if amount <= 0 then
        notify(src, 'Fine amount must be greater than 0.')
        return
    end

    if amount > Config.MaxFineAmount then
        notify(src, ('Fine amount too high. Max: %s'):format(Config.MaxFineAmount))
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    notify(src, ('Issued $%s fine to %s.'):format(amount, GetPlayerName(target) or target))

    local message = ('You received a $%s fine.'):format(amount)
    if reason ~= '' then
        message = message .. ' Reason: ' .. reason
    end
    notify(target, message)

    -- Add your economy integration here.
end)

RegisterNetEvent('k4_police:jail', function(target, minutes, reason)
    local src = source
    target = tonumber(target)
    minutes = math.floor(tonumber(minutes) or 0)
    reason = tostring(reason or '')

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if minutes <= 0 then
        notify(src, 'Jail minutes must be greater than 0.')
        return
    end

    if minutes > Config.MaxJailMinutes then
        notify(src, ('Jail time too high. Max: %s minute(s).'):format(Config.MaxJailMinutes))
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not isPlayerNearby(src, target) then
        notify(src, 'Target is too far away.')
        return
    end

    jailedUntil[target] = os.time() + (minutes * 60)
    cuffed[target] = false
    escortedBy[target] = nil

    TriggerClientEvent('k4_police:setEscorted', target, false, nil)
    TriggerClientEvent('k4_police:setCuffed', target, false)
    TriggerClientEvent('k4_police:sendToJail', target, Config.JailSpawnPosition, minutes, reason)

    notify(src, ('Jailed %s for %s minute(s).'):format(GetPlayerName(target) or target, minutes))

    local targetMessage = ('You were jailed for %s minute(s).'):format(minutes)
    if reason ~= '' then
        targetMessage = targetMessage .. ' Reason: ' .. reason
    end
    notify(target, targetMessage)
end)

RegisterNetEvent('k4_police:unjail', function(target)
    local src = source
    target = tonumber(target)

    if not target or not GetPlayerName(target) then
        notify(src, 'Invalid target.')
        return
    end

    if not canUsePoliceActions(src) then
        return
    end

    if not jailedUntil[target] then
        notify(src, 'Target is not jailed.')
        return
    end

    releasePlayerFromJail(target, src)
end)

RegisterNetEvent('k4_police:call911', function(message)
    local src = source
    message = tostring(message or '')
    if message == '' then
        return
    end

    local playerName = GetPlayerName(src) or ('ID %s'):format(src)
    local ped = GetPlayerPed(src)
    if ped <= 0 then
        return
    end

    local coords = GetEntityCoords(ped)
    notify(src, 'Your 911 call has been sent.')

    for _, playerId in ipairs(GetPlayers()) do
        local policeId = tonumber(playerId)
        if policeId and isPolice(policeId) then
            if not Config.RequireDutyForActions or onDuty[policeId] then
                TriggerClientEvent('k4_police:dispatch911', policeId, playerName, message, coords)
            end
        end
    end
end)
