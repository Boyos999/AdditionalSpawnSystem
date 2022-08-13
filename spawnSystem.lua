local spawnSystem = {}

require("custom.AdditionalSpawnSystem.spawnConfig")

local spawnTable = {
    cell = {},
    refId = {},
    uniqueIndex = {},
    npcTemplates = {},
    creatureTemplates = {},
    inventoryTemplates = {}
}

local pendingCells = {}

local trackedSpawns = {}
local pendingRespawns = {}

local respawnTimer

function spawnSystemRespawnTimer()
    if trackedSpawns ~= nil then
        for cellDescription,respawns in pairs(trackedSpawns) do
            local spawnIndexes = {}
            local objectsToDelete = {}
            local currentTime = os.time()
            local unTrackUniqueIndexes = {}
            local spawnCount = 0
            for uniqueIndex,respawn in pairs(respawns) do
                local respawnTime = respawn.timestamp+spawnTable.cell[cellDescription][respawn.spawnIndex].respawn
                if currentTime >= respawnTime then
                    if spawnIndexes[respawn.spawnIndex] == nil then
                        spawnIndexes[respawn.spawnIndex] = 1
                    else
                        spawnIndexes[respawn.spawnIndex] = spawnIndexes[respawn.spawnIndex] + 1
                    end
                    if spawnConfig.respawnCleanCorpse and respawn.deleted == false then
                        table.insert(objectsToDelete, uniqueIndex)
                    end
                    table.insert(unTrackUniqueIndexes, uniqueIndex)
                    spawnCount = spawnCount + 1
                end
            end
            if LoadedCells[cellDescription] ~= nil and tableHelper.isEmpty(spawnIndexes) == false then
                --active respawns
                tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: "..spawnCount.." Objects needing respawn in "..cellDescription.." spawning immediately")
                for _,uniqueIndex in pairs(objectsToDelete) do
                    logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
                end 
                spawnSystem.processCell(cellDescription, spawnIndexes)
                spawnSystem.unTrackSpawns(cellDescription, unTrackUniqueIndexes)
            elseif tableHelper.isEmpty(spawnIndexes) == false then
                --Add to pending respawns for this cell
                tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: "..spawnCount.." Objects needing respawn in "..cellDescription.." added to pending respawns")
                if pendingRespawns[cellDescription] == nil then
                    pendingRespawns[cellDescription] = {
                        pendingSpawnIndexes = tableHelper.deepCopy(spawnIndexes),
                        pendingDeletes = tableHelper.deepCopy(objectsToDelete)
                    }
                else
                    tableHelper.merge(pendingRespawns[cellDescription].pendingSpawnIndexes,spawnIndexes)
                    tableHelper.merge(pendingRespawns[cellDescription].pendingDeletes,objectsToDelete)
                end
                spawnSystem.unTrackSpawns(cellDescription, unTrackUniqueIndexes)
                spawnSystem.savePendingRespawns()
            else
                --nothing needs to respawn now
                tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: No objects need respawning")
            end
        end
        spawnSystem.saveTrackedRespawns()
    end
    tes3mp.RestartTimer(respawnTimer,spawnConfig.globalRespawnInterval*1000)
end

function spawnSystem.saveTrackedRespawns()
    jsonInterface.save("custom/trackedRespawns.json",trackedSpawns)
end

function spawnSystem.savePendingRespawns()
    jsonInterface.save("custom/pendingRespawns.json",pendingRespawns)
end

function spawnSystem.unTrackSpawns(cellDescription, unTrackIndexes)
    local newTrackedSpawns = {}
    for uniqueIndex,respawn in pairs(trackedSpawns[cellDescription]) do
        if tableHelper.containsValue(unTrackIndexes, uniqueIndex) then
        else
            newTrackedSpawns[uniqueIndex] = respawn
        end
    end
    trackedSpawns[cellDescription] = tableHelper.deepCopy(newTrackedSpawns)
end

function spawnSystem.settingValueParser(value)
    if type(value) == "table" then
        local rand = math.random(1,table.getn(value))
        return value[rand]
    else
        return value
    end
end

function spawnSystem.buildInventory(templateName)
    local templateData = spawnTable.inventoryTemplates[templateName]
    local inv = {}

    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Building inventory from template "..templateName)

    for _,items in pairs(templateData) do
        local item = {}
        --If this entry in the table is a single formatted item
        if items.id ~= nil then
            item = items
        --If this entry is either a string or array of strings/formatted items
        else
            item = spawnSystem.settingValueParser(items)
        end
        --If the returned item is a formatted item
        if type(item) == "table" then
            if item.count == nil then
                item.count = 1
            end
            table.insert(inv, item)
        --If the returned item is a string
        elseif type(item) == "string" then
            table.insert(inv, {id = item, count = 1})
        end
    end

    return inv
end

function spawnSystem.buildNpc(templateName)
    local templateData = spawnTable.npcTemplates[templateName]
    local recordData = {autoCalc = 1}
    local recordStore = RecordStores["npc"]
    local id = recordStore:GenerateRecordId()
    local pid = tableHelper.getAnyValue(Players).pid
    local textGender

    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Building custom NPC record "..id.." for "..templateName)

    for key,value in pairs(templateData) do
        --If a value on the template is an array pick a random entry
        local selectedValue = spawnSystem.settingValueParser(value)
        if key == "gender" then
            textGender = selectedValue
            if selectedValue == "male" then
                recordData[key] = 1
            elseif selectedValue == "female" then
                recordData[key] = 0
            end
        elseif key == "invTemplate" then
            recordData["items"] = spawnSystem.buildInventory(selectedValue)
        else
            recordData[key] = selectedValue
        end
    end

    --Fill in required settings with random values if unspecified
    for _,setting in pairs(spawnConfig.npcRequired) do
        if recordData[setting] == nil and recordData["baseId"] == nil then
            if setting == "name" then
                recordData[setting] = templateName
            elseif setting == "level" then
                recordData[setting] = math.random(spawnConfig.level[1],spawnConfig.level[2])
            elseif setting == "race" or setting == "class" then
                recordData[setting] = spawnConfig[setting][math.random(1,table.getn(spawnConfig[setting]))]
            elseif setting == "gender" then
                recordData[setting] = math.random(0,1)
                textGender = spawnConfig[setting][recordData[setting]+1]
            elseif setting == "hair" or setting == "head" then
                local appearanceTable = spawnConfig.npcInfo[recordData.race][textGender][setting]
                recordData[setting] = appearanceTable[math.random(1,table.getn(appearanceTable))]
            end
        end
    end

    recordStore.data.generatedRecords[id] = recordData
    for _, player in pairs(Players) do
        if not tableHelper.containsValue(Players[pid].generatedRecordsReceived, id) then
            table.insert(player.generatedRecordsReceived, id)
        end
    end

    tes3mp.ClearRecords()
    tes3mp.SetRecordType(enumerations.recordType[string.upper("npc")])
    packetBuilder.AddNpcRecord(id, recordData)
    tes3mp.SendRecordDynamic(pid, true, false)

    return id
end

function spawnSystem.buildCreature(templateName)
    local templateData = spawnTable.creatureTemplates[templateName]
    local recordData = {}
    local recordStore = RecordStores["creature"]
    local id = recordStore:GenerateRecordId()
    local pid = tableHelper.getAnyValue(Players).pid

    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Building custom creature record "..id.." for "..templateName)

    for key,value in pairs(templateData) do
        local selectedValue
        --Handle damage differently because a single "value" will be a table
        if key == "damageThrust" or key == "damageSlash" or key == "damageChop" then
            if type(value) == "table" and type(value[1]) ~= "table" then
                selectedValue = value
            else
                selectedValue = spawnSystem.settingValueParser(value)
            end
        else
            selectedValue = spawnSystem.settingValueParser(value)
        end

        if key == "invTemplate" then
            recordData["items"] = spawnSystem.buildInventory(selectedValue)
        else
            recordData[key] = selectedValue
        end
    end

    --tes3mp can't create creatures without baseIds due to not having all the record settings implemented
    if recordData["baseId"] == nil then
        recordData["baseId"] = "cliff racer"
        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Someone didn't read the config and didn't set a baseId, defaulting to cliff racer")
    end

    recordStore.data.generatedRecords[id] = recordData
    for _, player in pairs(Players) do
        if not tableHelper.containsValue(Players[pid].generatedRecordsReceived, id) then
            table.insert(player.generatedRecordsReceived, id)
        end
    end

    tes3mp.ClearRecords()
    tes3mp.SetRecordType(enumerations.recordType[string.upper("creature")])
    packetBuilder.AddCreatureRecord(id, recordData)
    tes3mp.SendRecordDynamic(pid, true, false)

    return id
end

function spawnSystem.spawnAtActors(spawnList,cellDescription)
    local objects = {}
    local templateBuilt = false

    for _,spawn in pairs(spawnList) do
        local numSpawns = spawn.spawnData.count
        local objectData, templateBuilt = spawnSystem.getSpawnData(spawn.spawnData)
        objectData.location = spawn.location

        if spawn.spawnData.useMult then
            local spawnMult = 1
            if LoadedCells[cellDescription].isExterior then
                spawnMult = spawnConfig.extSpawnMult
            else
                spawnMult = spawnConfig.intSpawnMult
            end
            numSpawns = math.floor(numSpawns*spawnMult)
        end

        if numSpawns >=1 then
            for i=1,numSpawns do
                table.insert(objects,objectData)
            end
        end

    end

    if templateBuilt then
        RecordStores["npc"]:Save()
        RecordStores["creature"]:Save()
    end

    if not tableHelper.isEmpty(objects) then
        logicHandler.CreateObjects(cellDescription,objects,"spawn")
    end
end

function spawnSystem.getSpawnData(spawn)
    local object = {}
    local templateBuilt = false

    --If this spawn has a template build it
    if spawn.template ~= nil then
        if spawnTable.npcTemplates[spawn.template] ~= nil then
            object.refId = spawnSystem.buildNpc(spawn.template)
        elseif spawnTable.creatureTemplates[spawn.template] ~= nil then
            object.refId = spawnSystem.buildCreature(spawn.template)
        end
        templateBuilt = true
    else
        object.refId = spawn.refId
    end

    if spawn.scale ~= nil then
        object.scale = spawn.scale
    else
        object.scale = 1
    end

    return object, templateBuilt
end

function spawnSystem.processActors(cellDescription)
    local cellData = LoadedCells[cellDescription].data

    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Processing Actor based spawns for "..cellDescription)

    local spawnList = {}

    --Identify actors in cell we want to do anything with
    for _,uniqueIndex in pairs(cellData.packets.actorList) do
        
        --Skip actors placed via cell spawns
        if pendingCells[cellDescription] ~= nil and tableHelper.containsValue(pendingCells[cellDescription],uniqueIndex) and spawnConfig.actorSpawnOnCellSpawn == false then
            tes3mp.LogMessage(enumerations.log.VERBOSE,"SpawnSystem: Skipped Actor with uniqueIndex " ..uniqueIndex.." because they were spawned by the cell spawn list for "..cellDescription)
        else
            local actor = cellData.objectData[uniqueIndex]

            if actor.location ~= nil then
                if spawnTable.uniqueIndex[uniqueIndex] ~= nil then
                    for _,spawn in pairs(spawnTable.uniqueIndex[uniqueIndex]) do
                        table.insert(spawnList,{spawnData = spawn, location = actor.location })
                    end
                    tes3mp.LogMessage(enumerations.log.VERBOSE,"SpawnSystem: Actor matched by Unique Index: "..uniqueIndex.."|"..actor.refId.."|"..actor.location.posX.."|"..actor.location.posY.."|"..actor.location.posZ)
                end

                if spawnTable.refId[actor.refId] ~= nil then
                    for _,spawn in pairs(spawnTable.refId[actor.refId]) do
                        table.insert(spawnList,{spawnData = spawn, location = actor.location})
                    end
                    tes3mp.LogMessage(enumerations.log.VERBOSE,"SpawnSystem: Actor matched by RefId: "..uniqueIndex.."|"..actor.refId.."|"..actor.location.posX.."|"..actor.location.posY.."|"..actor.location.posZ)
                end
            else
                tes3mp.LogMessage(enumerations.log.WARN,"SpawnSystem: Actor Location not found for "..uniqueIndex.."|"..actor.refId)
            end
        end
    end
    spawnSystem.spawnAtActors(spawnList,cellDescription)
    pendingCells[cellDescription] = nil
    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Removed cell " .. cellDescription .." from cells pending spawns")
end

function spawnSystem.processCell(cellDescription, spawnIndexes)
    tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Processing Cell based spawns for "..cellDescription)
    if pendingCells[cellDescription] == nil or spawnIndexes ~= nil then
        local placeObjects = {}
        local spawnObjects = {}
        local rePlaceObjects = {}
        local reSpawnObjects = {}
        local reSpawnIndexes = {}
        local rePlaceIndexes = {}
        local uniqueIndexes = {}
        local totalPlace = 0
        local totalSpawn = 0
        local templateBuilt = false

        for spawnIndex,spawn in pairs(spawnTable.cell[cellDescription]) do
            if spawnIndexes == nil or spawnIndexes[spawnIndex] ~= nil then
                local object = {}
                if spawn.packetType == "spawn" then
                    object, templateBuilt = spawnSystem.getSpawnData(spawn)
                    object.location = spawn.location
                    local spawnCount = spawn.count
                    if spawnIndexes ~= nil and spawnIndexes[spawnIndex] ~= nil then
                        spawnCount = spawnIndexes[spawnIndex]
                    end
                    for i=1,spawnCount do
                        if spawn.respawn ~= nil then
                            table.insert(reSpawnObjects,object)
                            table.insert(reSpawnIndexes,spawnIndex)
                        else
                            table.insert(spawnObjects,object)
                        end
                        totalSpawn = totalSpawn + 1
                    end
                elseif spawn.packetType == "place" then
                    object.refId = spawn.refId
                    object.location = spawn.location
                    object.count = spawn.count
                    object.charge = -1
                    object.enchantmentCharge = -1
                    object.soul = ""
                    if spawn.respawn ~= nil then
                        table.insert(rePlaceObjects,object)
                        table.insert(rePlaceIndexes,spawnIndex)
                    else
                        table.insert(placeObjects,object)
                    end
                    totalPlace = totalPlace + 1
                end
            end
        end

        if templateBuilt then
            RecordStores["npc"]:QuicksaveToDrive()
            RecordStores["creature"]:QuicksaveToDrive()
        end

        --Place non-actors and spawn actors
        uniqueIndexes = logicHandler.CreateObjects(cellDescription,placeObjects,"place")
        tableHelper.merge(uniqueIndexes,logicHandler.CreateObjects(cellDescription,spawnObjects,"spawn"),true)

        --Respawning objects need to be tracked separately
        uniqueRePlaceIndexes = logicHandler.CreateObjects(cellDescription,rePlaceObjects,"place")
        uniqueReSpawnIndexes = logicHandler.CreateObjects(cellDescription,reSpawnObjects,"spawn")
        local currentTime = os.time()
        for i,spawnIndex in pairs(reSpawnIndexes) do
            trackedSpawns[cellDescription][uniqueReSpawnIndexes[i]] = {
                spawnIndex = spawnIndex,
                timestamp = currentTime,
                needsRespawn = false,
                deleted = false
            }  
            tes3mp.LogMessage(enumerations.log.VERBOSE,"SpawnSystem: Added "..uniqueReSpawnIndexes[i].." to "..cellDescription.." pending respawn for spawnIndex: "..spawnIndex)
        end
        for i,spawnIndex in pairs(rePlaceIndexes) do
            trackedSpawns[cellDescription][uniqueRePlaceIndexes[i]] = {
                spawnIndex = spawnIndex,
                timestamp = currentTime,
                needsRespawn = false
            }
            tes3mp.LogMessage(enumerations.log.VERBOSE,"SpawnSystem: Added "..uniqueRePlaceIndexes[i].." to "..cellDescription.." pending respawn for spawnIndex: "..spawnIndex)
        end

        if tableHelper.isEmpty(trackedSpawns[cellDescription]) == false then
            spawnSystem.saveTrackedRespawns()
        end

        tableHelper.merge(uniqueIndexes, uniqueRePlaceIndexes, true)
        tableHelper.merge(uniqueIndexes, uniqueReSpawnIndexes, true)

        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Placed "..totalPlace.." objects and spawned "..totalSpawn.." actors for "..cellDescription)

        --Store unique indexes of placed/spawned objects so we don't duplicate them in processActors()
        pendingCells[cellDescription] = uniqueIndexes
    else
        tes3mp.LogMessage(enumerations.log.WARN,"SpawnSystem: Skipped spawns for cell "..cellDescription.." because spawns have already been processed")
    end
end

function spawnSystem.OnActorList(eventStatus,pid,cellDescription,actors)
    --Enter Caius's house seems to cause a nil cellDescription followed by server crash without this check
    if eventStatus.validCustomHandlers and eventStatus.validDefaultHandler and cellDescription ~= nil then
        if tableHelper.containsValue(pendingCells,cellDescription) then
            --process cell immediately because we don't have to wait for position data
            if spawnTable.cell[cellDescription] ~= nil then
                spawnSystem.processCell(cellDescription)
            end

            --process actors on a delay so there's time for the position packets to arrive
            local actorListTimer = tes3mp.CreateTimerEx("spawnSystemTimerFunc",spawnConfig.actorSpawnTimer,"s",cellDescription)
            tes3mp.StartTimer(actorListTimer)
        end
    end
end

function spawnSystemTimerFunc(cellDescription)
    local unloadCell = false
    if LoadedCells[cellDescription] ~= nil then
        LoadedCells[cellDescription]:SaveActorPositions()
    else
        logicHandler.LoadCell(cellDescription)
        unloadCell = true
        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Loaded cell " .. cellDescription .." because the last player to enter left before spawns could be processed")
    end
    spawnSystem.processActors(cellDescription)
    if unloadCell and LoadedCells[cellDescription]:GetVisitorCount() == 0 then
        logicHandler.UnloadCell(cellDescription)
        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Unloaded cell " .. cellDescription .." after spawns were processed")
    end
end

function spawnSystem.OnCellLoad(eventStatus,pid,cellDescription)
    if eventStatus.validCustomHandlers and eventStatus.validDefaultHandler then
        --If this cell has not been initialized or has been reset add it to the list of cells that need spawns
        if LoadedCells[cellDescription].data.loadState.hasFullActorList ~= true then
            trackedSpawns[cellDescription] = {}
            table.insert(pendingCells,cellDescription)
            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Added cell " .. cellDescription .." to cells pending spawns")
        elseif pendingRespawns[cellDescription] ~= nil then
            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Processing queued respawns for ".. cellDescription)
            for _,uniqueIndex in pairs(pendingRespawns[cellDescription].pendingDeletes) do
                logicHandler.DeleteObjectForEveryone(cellDescription, uniqueIndex)
            end 
            spawnSystem.processCell(cellDescription,pendingRespawns[cellDescription].pendingSpawnIndexes)
            pendingRespawns[cellDescription] = nil
            spawnSystem.savePendingRespawns()
        end
    end
end

--Merge spawn jsons together
function spawnSystem.init()
    for _,tableEntry in pairs(spawnConfig.spawnTables) do
        local jsonTable = jsonInterface.load("custom/spawnData/"..tableEntry.name)
        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Loading "..tableEntry.name.." into spawn table")
        --spawnType will be cell, refId, uniqueIndex, npcTemplates, or creatureTemplates
        for spawnType,subTable in pairs(jsonTable) do
            if tableHelper.isEmpty(spawnTable[spawnType]) then
                spawnTable[spawnType] = subTable
            else 
                --id will be a cell id, refId, uniqueIndex, or templateName
                for id, spawnList in pairs(subTable) do
                    if spawnTable[spawnType][id] == nil then
                        spawnTable[spawnType][id] = spawnList
                    elseif tableEntry.mergeType == 0 then
                        spawnTable[spawnType][id] = spawnList
                        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Overwriting "..spawnType.." entry for "..id.." with entry from "..tableEntry.name)
                    elseif tableEntry.mergeType == 1 then
                        if spawnType == "cell" or spawnType == "refId" or spawnType == "uniqueIndex" then
                            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Merging "..spawnType.." entry for "..id.." with entry from "..tableEntry.name)
                            for _,spawn in pairs(spawnList) do
                                table.insert(spawnTable[spawnType][id],spawn)
                            end
                        else
                            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Skipping "..spawnType.." entry for "..id.." from "..tableEntry.name.." because templates cannot be merged")
                        end
                    elseif tableEntry.mergeType == 2 then
                        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Skipping "..spawnType.." entry for "..id.." from "..tableEntry.name)
                    end
                end
            end
        end
    end
    --Establish randomseed on server start
    math.randomseed(os.time())
    math.random()
    math.random()
    math.random()
    math.random()
    trackedSpawns = jsonInterface.load("custom/trackedRespawns.json")
    if trackedSpawns == nil then
        trackedSpawns = {}
    end
    pendingRespawns = jsonInterface.load("custom/pendingRespawns.json")
    if pendingRespawns == nil then
        pendingRespawns = {}
    end
    respawnTimer = tes3mp.CreateTimer("spawnSystemRespawnTimer",spawnConfig.globalRespawnInterval*1000)
    tes3mp.StartTimer(respawnTimer)
end

function spawnSystem.OnActorDeath(eventStatus,pid,cellDescription,actors)
    if eventStatus.validCustomHandlers and eventStatus.validDefaultHandler then
        if trackedSpawns[cellDescription] ~= nil then
            if tableHelper.isEmpty(trackedSpawns[cellDescription]) == false then
                for uniqueIndex,actor in pairs(actors) do
                    if trackedSpawns[cellDescription][uniqueIndex] ~= nil then
                        trackedSpawns[cellDescription][uniqueIndex].needsRespawn = true
                        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: "..uniqueIndex.." ("..actor.refId..") died and is marked for respawn")
                    end
                end
            end
        end
    end
end

function spawnSystem.OnObjectDelete(eventStatus,pid, cellDescription, objects, targetPlayers)
    if eventStatus.validCustomHandlers and eventStatus.validDefaultHandler then
        if trackedSpawns[cellDescription] ~= nil then
            if tableHelper.isEmpty(trackedSpawns[cellDescription]) == false then
                for uniqueIndex, object in pairs(objects) do
                    if trackedSpawns[cellDescription][uniqueIndex] ~= nil then
                        if trackedSpawns[cellDescription][uniqueIndex].needsRespawn == true then
                            --This is probably a corpse
                            trackedSpawns[cellDescription][uniqueIndex].deleted = true
                            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: "..uniqueIndex.." ("..object.refId..") corpse was deleted and is marked as deleted")
                        else
                            trackedSpawns[cellDescription][uniqueIndex].needsRespawn = true
                            tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: "..uniqueIndex.." ("..object.refId..") was deleted and is marked for respawn")
                        end
                    end
                end
            end
        end
    end
end

function spawnSystem.OnPlayerDisconnect(eventStatus,pid)
    if tableHelper.isEmpty(Players) then
        spawnSystem.saveTrackedRespawns()
        spawnSystem.savePendingRespawns()
        tes3mp.LogMessage(enumerations.log.INFO,"SpawnSystem: Saved respawn tracking since the last player left the server")
    end
end

customEventHooks.registerHandler("OnCellLoad",spawnSystem.OnCellLoad)
customEventHooks.registerHandler("OnActorList",spawnSystem.OnActorList)
customEventHooks.registerHandler("OnServerPostInit",spawnSystem.init)
customEventHooks.registerHandler("OnActorDeath",spawnSystem.OnActorDeath)
customEventHooks.registerHandler("OnObjectDelete",spawnSystem.OnObjectDelete)
customEventHooks.registerHandler("OnPlayerDisconnect",spawnSystem.OnPlayerDisconnect)

return spawnSystem