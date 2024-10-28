Config = {}

Config.target = {
    system = 'ox_target', -- ox_target | qb-target
    distance = 3.0,
}

Config.progressBar = {
    system = 'ox_lib', -- ox_lib | ESX | QBCore
    duration = 4500
}

Config.pumpkinModels = {
    `prop_bin_01a`,
    `prop_bin_05a`,
    `prop_bin_07c`,
    `prop_bin_08a`,
    `prop_dumpster_01a`,
    `prop_dumpster_02a`,
    `prop_postbox_01a`,
    `prop_rub_binbag_01a`,
    `prop_rub_binbag_03b`
}

Config.ped = {
    model = 's_m_o_busker_01',
    renderDistance = 30,
    coords = vec4(195.12, -923.0, 30.69, 234.18),
    anim = {
        dict = 'timetable@ron@ig_3_couch',
        name = 'base',
        flag = 1
    },
    blip = {
        enable = true,
        scale = 0.8,
        sprite = 113,
        color = 47,
        label = 'Halloween Pumpkin Hunt'
    }
}

Config.notify = function(message, type)
    lib.notify({
        title = 'Pumpkin Hunt',
        description = message,
        type = type or 'info'
    })
end

if not IsDuplicityVersion() then return Config end

local Framework = nil
local Inventory = nil

if GetResourceState('es_extended') ~= 'missing' then
    Framework = 'ESX'
    ESX = exports.es_extended:GetSharedObject()
elseif GetResourceState('qbx_core') ~= 'missing' then
    Framework = 'QBOX'
elseif GetResourceState('qb-core') ~= 'missing' then
    Framework = 'QBCore'
    QBCore = exports['qb-core']:GetCoreObject()
end

if GetResourceState('ox_inventory') ~= 'missing' then
    Inventory = 'ox'
elseif GetResourceState('qb-inventory') ~= 'missing' then
    Inventory = 'QB'
end

Config.database = {
    tableName = Framework == 'ESX' and 'users' or 'players',
    identifierColumnName = Framework == 'ESX' and 'identifier' or 'citizenid AS identifier',
    firstname = Framework == 'ESX' and "firstname" or "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.firstname')) AS firstname",
    lastname = Framework == 'ESX' and "lastname" or "JSON_UNQUOTE(JSON_EXTRACT(charinfo, '$.lastname')) AS lastname"
}

Config.inventory = {
    canCarry = function(source)
        if Inventory == 'ox' then
            return exports.ox_inventory:CanCarryItem(source, 'halloween_pumpkin', 1)
        elseif Inventory == 'QB' then
            local Player = QBCore.Functions.GetPlayer(source)
            return Player.Functions.AddItem('halloween_pumpkin', 1)
        end
        return false
    end,
    addItem = function(source)
        if Inventory == 'ox' then
            exports.ox_inventory:AddItem(source, 'halloween_pumpkin', 1)
        elseif Inventory == 'QB' then
            local Player = QBCore.Functions.GetPlayer(source)
            Player.Functions.AddItem('halloween_pumpkin', 1)
        end
    end,
    getCount = function(source)
        if Inventory == 'ox' then
            return exports.ox_inventory:GetItem(source, 'halloween_pumpkin', nil, true)
        elseif Inventory == 'QB' then
            local Player = QBCore.Functions.GetPlayer(source)
            return Player.Functions.GetItemByName('halloween_pumpkin').count
        end
        return 0
    end,
    removeItem = function(source, count)
        if Inventory == 'ox' then
            exports.ox_inventory:RemoveItem(source, 'halloween_pumpkin', count)
        elseif Inventory == 'QB' then
            local Player = QBCore.Functions.GetPlayer(source)
            Player.Functions.RemoveItem('halloween_pumpkin', count)
        end
    end
}

Config.framework = {
    getIdentifier = function(source)
        if Framework == 'ESX' then
            local xPlayer = ESX.GetPlayerFromId(source)
            return xPlayer and xPlayer.identifier or nil
        elseif Framework == 'QBCore' then
            local Player = QBCore.Functions.GetPlayer(source)
            return Player and Player.PlayerData.citizenid or nil
        elseif Framework == 'QBOX' then
            local Player = exports.qbx_core:GetPlayer(source)
            return Player and Player.PlayerData.citizenid or nil
        end
    end,

    getName = function(identifier)
        if Framework == 'ESX' then
            local xPlayer = ESX.GetPlayerFromIdentifier(identifier)

            if xPlayer then
                return xPlayer.get('firstName'), xPlayer.get('lastName')
            else
                local result = MySQL.single.await('SELECT firstname, lastname FROM users WHERE identifier = ?', {identifier})
                if result then
                    return result.firstname, result.lastname
                end
            end
        elseif Framework == 'QBCore' then
            local Player = QBCore.Functions.GetPlayerByCitizenId(identifier) or QBCore.Functions.GetOfflinePlayerByCitizenId(identifier)
            return Player and Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname
        elseif Framework == 'QBOX' then
            local Player = exports.qbx_core:GetPlayerByCitizenId(identifier) or exports.qbx_core:GetOfflinePlayer(identifier)

            if Player then
                return Player.PlayerData.charinfo.firstname, Player.PlayerData.charinfo.lastname
            else
                return nil
            end
        end
    end
}


return Config