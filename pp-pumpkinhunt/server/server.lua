local config = require 'config/config'
local pickedup = {}
local pumpkinCheck = {}
local rankingData = {ranking = {}, blocked = false}

lib.callback.register('pp-halloween:checkPumpkin', function(source, coords)
    if rankingData.blocked then return false end
    local sourcepicked = pickedup[source] or {}

    for _, pumpkinCoords in ipairs(sourcepicked) do
        if #(coords - pumpkinCoords) <= 0.5 then
            return false
        end
    end

    pumpkinCheck[source] = coords

    SetTimeout(10000, function()
        pumpkinCheck[source] = nil
    end)

    return true
end)

lib.callback.register('pp-halloween:pickupPumpkin', function(source, coords)
    if rankingData.blocked then return false end
    local src = source
    local sourcepicked = pickedup[src] or {}

    local pumpkinData = pumpkinCheck[src]

    if not pumpkinData then
        return false, 'cannot_collect'
    end

    if #(coords - pumpkinData) > 0.5 then
        return false, 'collect_too_far'
    end

    if config.inventory.canCarry(src) then
        config.inventory.addItem(src)
        table.insert(sourcepicked, coords)
        pickedup[src] = sourcepicked
        pumpkinCheck[src] = nil
    else
        return false, 'collect_full_inventory'
    end
    return true, 'collect_success'
end)

lib.callback.register('pp-halloween:depositPumpkins', function(source)
    local identifier = config.framework.getIdentifier(source)
    if not identifier then return false end
    local count = config.inventory.getCount(source)

    if count > 0 then
        local playerPumpkins = rankingData.ranking[identifier] or 0
        rankingData.ranking[identifier] = playerPumpkins + count

        config.inventory.removeItem(source, count)
        return true, count
    end

    return false
end)

lib.callback.register('pp-halloween:getRankingData', function(source)
    local pIdentifier = config.framework.getIdentifier(source)
    if not pIdentifier then return end
    local query = string.format([[
        SELECT %s, IFNULL(collected_pumpkins, 0) AS collected_pumpkins, %s, %s
        FROM %s
        ORDER BY collected_pumpkins DESC
        LIMIT 10
    ]], config.database.identifierColumnName, config.database.firstname, config.database.lastname, config.database.tableName)

    local dbRanking = MySQL.query.await(query)
    local totalPlayers = MySQL.scalar.await("SELECT COUNT(*) FROM " .. config.database.tableName)

    local sessionRanking = {}
    for identifier, pumpkins in pairs(rankingData.ranking) do
        table.insert(sessionRanking, {identifier = identifier, pumpkins = pumpkins})
    end

    table.sort(sessionRanking, function(a, b)
        return a.pumpkins > b.pumpkins
    end)

    local sessionTop10 = {}
    for i = 1, math.min(10, #sessionRanking) do
        table.insert(sessionTop10, sessionRanking[i])
    end

    local combinedRanking = {}
    local addedIdentifiers = {}

    for _, dbEntry in ipairs(dbRanking) do
        local identifier = dbEntry.identifier
        local sessionPumpkins = rankingData.ranking[identifier] or 0
        local totalPumpkins = (dbEntry.collected_pumpkins or 0) + sessionPumpkins

        table.insert(combinedRanking, {
            identifier = identifier,
            pumpkins = totalPumpkins,
            firstname = dbEntry.firstname,
            lastname = dbEntry.lastname
        })
        addedIdentifiers[identifier] = true
    end

    for _, sessionEntry in ipairs(sessionTop10) do
        local identifier = sessionEntry.identifier
        if not addedIdentifiers[identifier] and sessionEntry.pumpkins > 0 then
            local firstname, lastname = config.framework.getName(identifier)

            if firstname then
                table.insert(combinedRanking, {
                    identifier = identifier,
                    pumpkins = sessionEntry.pumpkins,
                    firstname = firstname,
                    lastname = lastname
                })
            end
        end
    end

    table.sort(combinedRanking, function(a, b)
        return a.pumpkins > b.pumpkins
    end)
    local top10 = {}
    for i = 1, math.min(10, #combinedRanking) do
        table.insert(top10, combinedRanking[i])
    end

    local playerPumpkins = rankingData.ranking[pIdentifier] or 0
    local playerPlace = 0

    for i, entry in ipairs(combinedRanking) do
        if entry.identifier == pIdentifier then
            playerPumpkins = entry.pumpkins
            playerPlace = i
            break
        end
    end

    local formattedTop10 = {}
    for _, playerData in ipairs(top10) do
        table.insert(formattedTop10, {
            identifier = playerData.identifier,
            name = playerData.firstname .. " " .. playerData.lastname,
            pumpkins = playerData.pumpkins
        })
    end

    return {
        data = formattedTop10,
        total = totalPlayers,
        player = {
            pumpkins = playerPumpkins,
            place = playerPlace
        }
    }
end)

local function saveDataToDatabase()
    local totalPlayers = 0
    local totalPumpkins = 0
    local cases = {}
    local ids = {}

    for identifier, pumpkinCount in pairs(rankingData.ranking) do
        table.insert(cases, string.format("WHEN '%s' THEN collected_pumpkins + %d", identifier, pumpkinCount))
        table.insert(ids, string.format("'%s'", identifier))
        totalPlayers = totalPlayers + 1
        totalPumpkins = totalPumpkins + pumpkinCount
    end

    if #cases > 0 then
        local updateQuery = string.format([[
            UPDATE %s
            SET collected_pumpkins = CASE %s
                %s
            END
            WHERE %s IN (%s)
        ]], config.database.tableName, config.database.identifierColumnName, table.concat(cases, " "), config.database.identifierColumnName, table.concat(ids, ", "))

        MySQL.query(updateQuery, {}, function()
            rankingData = { ranking = {}, blocked = true }
            lib.print.info(('Updated %s players with a total of %s pumpkins collected.'):format(totalPlayers, totalPumpkins))
        end)
    end
end

AddEventHandler('txAdmin:events:scheduledRestart', function(eventData)
    if eventData.secondsRemaining == 60 then
        CreateThread(function()
            Wait(45000)
            saveDataToDatabase()
        end)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() and not rankingData.blocked then
        saveDataToDatabase()
    end
end)