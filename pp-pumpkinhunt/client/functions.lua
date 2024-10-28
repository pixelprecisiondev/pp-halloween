function collectPumpkin(entity, coords)
    local playerCoords = GetEntityCoords(cache.ped)
    local headingToEntity = GetHeadingFromVector_2d(coords.x - playerCoords.x, coords.y - playerCoords.y)

    SetEntityHeading(playerPed, headingToEntity)

    local canPickUp = lib.callback.await('pp-halloween:checkPumpkin', false, coords)
    if not canPickUp then
        config.notify(locale('already_collected'), 'error')
        return
    end

    local success = progressBar()
    if success then
        local pickupSuccess, pickupMessage = lib.callback.await('pp-halloween:pickupPumpkin', false, coords)
        config.notify(locale(pickupMessage), pickupSuccess and 'success' or 'error')
    end
end

function progressBar()
    if config.progressBar.system == 'ox_lib' then
        return lib.progressBar({
            duration = config.progressBar.duration,
            label = locale('collecting_pumpkin'),
            useWhileDead = false,
            canCancel = true,
            anim = {
                dict = 'anim@scripted@freemode@ig5_collect_weapons@heeled@',
                clip = 'collect_weapon_1h',
                flag = 2
            },
        })
    elseif config.progressBar.system == 'ESX' then
        local p = promise.new()
        exports["esx_progressbar"]:Progressbar(locale('collecting_pumpkin'), config.progressBar.duration, {
            animation ={
                type = "anim",
                dict = "anim@scripted@freemode@ig5_collect_weapons@heeled@",
                lib ="collect_weapon_1h",
                flag = 2
            },
            onFinish = function()
                p:resolve(true)
            end,
            onCancel = function()
                p:resolve(false)
            end
        })

        return Citizen.Await(p)
    elseif config.progressBar.system == 'QBCore' then
        local p = promise.new()
        exports['progressbar']:Progress({
            name = locale('collecting_pumpkin'):lower(),
            duration = config.progressBar.duration,
            label = locale('collecting_pumpkin'),
            useWhileDead = false,
            canCancel = true,
            animation = {
                animDict = "anim@scripted@freemode@ig5_collect_weapons@heeled@",
                anim = "collect_weapon_1h",
                flags = 2
            },
        }, function(cancelled)
            p:resolve(not cancelled)
        end)

        return Citizen.Await(p)
    end
end

function openMenu()
    local data = lib.callback.await('pp-halloween:getRankingData', false)
    if not data then return end
    SendNUIMessage({
        action = 'open',
        data = data
    })
    SetNuiFocus(true, true)
end