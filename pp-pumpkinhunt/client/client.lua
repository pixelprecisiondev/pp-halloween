config = require 'config/config'
local ped = nil
lib.locale()

if config.target.system == 'ox_target' then
    exports.ox_target:addModel(config.pumpkinModels, {
        {
            label = locale('collect_pumpkin'),
            icon = 'fas fa-hands',
            distance = config.target.distance,
            onSelect = function(data)
                collectPumpkin(data.entity, data.coords)
            end
        }
    })
elseif config.target.system == 'qb-target' then
    exports['qb-target']:AddTargetModel(config.pumpkinModels, {
        options = {
            {
                label = locale('collect_pumpkin'),
                icon = 'fas fa-hands',
                action = function(entity)
                    local entityCoords = GetEntityCoords(entity)
                    collectPumpkin(entity, entityCoords)
                end
            }
        },
        distance = config.target.distance
    })
end

lib.points.new({
    coords = config.ped.coords,
    distance = config.ped.renderDistance,
    onEnter = function()
        lib.requestModel(config.ped.model)
        ped = CreatePed(0, joaat(config.ped.model), config.ped.coords.x, config.ped.coords.y, config.ped.coords.z - 1, config.ped.coords.w, false)
        FreezeEntityPosition(ped, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetPedFleeAttributes(ped, 0, 0)
        SetEntityInvincible(ped, true)

        if config.ped.anim then
            lib.requestAnimDict(config.ped.anim.dict)

            TaskPlayAnim(ped, config.ped.anim.dict, config.ped.anim.name, 3.0, 3.0, -1, config.ped.anim.flag, 0, false, false, false)
            RemoveAnimDict(config.ped.anim.dict)
        end

        SetModelAsNoLongerNeeded(config.ped.model)
        if config.target.system == 'ox_target' then
            exports.ox_target:addLocalEntity(ped, {
                {
                    name = 'deposit_pumpkins',
                    label = 'Deposit Pumpkins',
                    icon = 'fas fa-arrow-up-from-bracket',
                    onSelect = function()
                        local success, count = lib.callback.await('pp-halloween:depositPumpkins', false)

                        if not success then
                            config.notify(locale('deposit_no_pumpkins'))
                        else
                            config.notify(locale('deposit_success', count))
                        end
                    end
                },
                {
                    name = 'open_ranking',
                    label = 'Open Ranking',
                    onSelect = openMenu,
                    icon = 'fas fa-ranking-star'
                }
            })
        end
    end,
    onExit = function()
        if DoesEntityExist(ped) then
            if config.target.system == 'ox_target' then
                exports.ox_target:removeLocalEntity(ped, {'deposit_pumpkins', 'open_ranking'})
            end
            DeleteEntity(ped)
            ped = nil
        end
    end
})

CreateThread(function()
    local ped = config.ped
    if ped.blip.enable then
        local blip = AddBlipForCoord(ped.coords.x, ped.coords.y, ped.coords.z)
        SetBlipSprite(blip, ped.blip.sprite)
        SetBlipDisplay(blip, 2)
        SetBlipScale(blip, ped.blip.scale)
        SetBlipColour(blip, ped.blip.color)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentSubstringPlayerName(ped.blip.label)
        EndTextCommandSetBlipName(blip)
    end
end)

RegisterNUICallback('close', function()
    SetNuiFocus(false, false)
end)

AddEventHandler('onResourceStop', function(resName)
    if resName == GetCurrentResourceName() then
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
            ped = nil
        end
    end
end)