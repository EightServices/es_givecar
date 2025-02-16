ESX = exports["es_extended"]:getSharedObject()

local currentLanguage = Locales[Config.Language]

local webhookFile = LoadResourceFile(GetCurrentResourceName(), 'webhook.json')
if webhookFile then
    local webhook = json.decode(webhookFile)
    webhookURL = webhook.webhook
end

RegisterCommand('givecar', function(source, args, rawCommand)
    local xPlayer = ESX.GetPlayerFromId(source)

    local allowedGroups = Config.GivecarPermissions or {}

    local hasPermission = false
    for _, group in ipairs(allowedGroups) do
        if xPlayer and xPlayer.getGroup() == group then
            hasPermission = true
            break
        end
    end

    if hasPermission then
        local targetId = tonumber(args[1])
        local vehicleModel = args[2]

        if targetId and vehicleModel then
            local targetPlayer = ESX.GetPlayerFromId(targetId)

            if targetPlayer then
                local plate = GenerateUniquePlate()
                local vehicleHash = GetHashKey(vehicleModel)
                local customPrimaryColor = {255, 255, 255}

                MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle, stored) VALUES (?, ?, ?, 1)',
                    {targetPlayer.identifier, plate, json.encode({model = vehicleHash, plate = plate, customPrimaryColor = customPrimaryColor})},
                    function(rowsAffected)
                        if rowsAffected > 0 then
                            local giverName = GetPlayerName(source)
                            local giverRockstarId = GetPlayerIdentifier(source)
                            local receiverName = GetPlayerName(targetId)
                            local receiverRockstarId = GetPlayerIdentifier(targetId)

                            local logMessage = string.format(currentLanguage.LogMessage, giverName, source, giverRockstarId, vehicleModel, receiverName, targetId, receiverRockstarId, vehicleModel, plate)

                            SendDiscordLog(logMessage)

                            TriggerClientEvent('esx:showNotification', source, string.format(currentLanguage.CarAssigned, vehicleModel, targetId, plate))                            
                            TriggerClientEvent('esx:showNotification', targetId, string.format(currentLanguage.GotCar, vehicleModel, plate))
                                                     
                        else
                            TriggerClientEvent('esx:showNotification', source, currentLanguage.DatabaseError)
                        end
                    end
                )
            else
                TriggerClientEvent('esx:showNotification', source, currentLanguage.UnknownPlayerID)
            end
        else
            TriggerClientEvent('esx:showNotification', source, currentLanguage.IncorrectUse)
        end
    else
        TriggerClientEvent('esx:showNotification', source, currentLanguage.NoPermissions)
    end
end, false)

function GenerateUniquePlate()
    local characters = Config.PlateCharacters
    local isPlateUnique = false
    local plate

    while not isPlateUnique do
        plate = ""
        for i = 1, 6 do
            local randomIndex = math.random(1, #characters)
            local randomChar = characters:sub(randomIndex, randomIndex)
            plate = plate .. randomChar
        end

        isPlateUnique = IsPlateUnique(plate)
    end

    return plate
end

function IsPlateUnique(plate)
    local isUnique = true

    MySQL.Async.fetchScalar('SELECT COUNT(*) FROM owned_vehicles WHERE plate = @plate', {['@plate'] = plate}, function(result)
        local count = tonumber(result) or 0
        if count > 0 then
            isUnique = false
        end
    end)

    return isUnique
end

function SendDiscordLog(message, username, avatarUrl)
    local currentTime = os.date(Locales.LogsOSDate)

    local embed = {
        {
            ["title"] = Locales.LogsTitle,
            ["color"] = Config.LogsColor,
            ["fields"] = {
                {["name"] = Locales.LogsMessage, ["value"] = message, ["inline"] = false},
                {["name"] = Locales.LogsTime, ["value"] = currentTime, ["inline"] = false},
            },
            ["footer"] = {
                ["text"] = Locales.LogsTitle,
            },
        }
    }

    local params = {
        username = Config.LogsUsername,
        avatar_url = Config.LogsAvatarURL,
    }

    PerformHttpRequest(webhookURL, function(err, text, headers) end, 'POST', json.encode({username = params.username, avatar_url = params.avatar_url, embeds = embed}), { ['Content-Type'] = 'application/json' })
end