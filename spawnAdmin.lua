local spawnAdmin = {}

local loadedSpawnList = {
    cell = {},
    refId = {},
    uniqueIndex = {},
    npcTemplates = {},
    creatureTemplates = {},
    inventoryTemplates = {}
}

require("custom.AdditionalSpawnSystem.spawnConfig")

function spawnAdmin.getPlayerLocation(pid)
    local cellDescription = tes3mp.GetCell(pid)
    local location = {
        posX = tes3mp.GetPosX(pid),
        posY = tes3mp.GetPosY(pid),
        posZ = tes3mp.GetPosZ(pid),
        rotX = tes3mp.GetRotX(pid),
        rotY = 0,
        rotZ = tes3mp.GetRotZ(pid)
    }

    return location, cellDescription
end

--ex usage /as <p/s> <t/r> <id>
function spawnAdmin.addSpawn(pid,cmd)
    if Players[pid].data.settings.staffRank >= spawnConfig.staffRankReq then
        if cmd[2] ~= nil and cmd[3] ~= nil and cmd[4] ~= nil then
            local packetType
            local idType
            local id = table.concat(cmd," ",4)
            local location, cellDescription = spawnAdmin.getPlayerLocation(pid)
            local spawnEntry = { count = 1, location = location }

            if cmd[2] == "s" or cmd[2] == "spawn" then
                spawnEntry.packetType = "spawn"
            elseif cmd[2] == "p" or cmd[2] == "place" then
                spawnEntry.packetType = "place"
            end

            if cmd[3] == "r" or cmd[3] == "refId" then
                spawnEntry.refId = id
            elseif cmd[3] == "t" or cmd[3] == "template" then
                spawnEntry.template = id
            end

            if loadedSpawnList.cell[cellDescription] == nil then
                loadedSpawnList.cell[cellDescription] = {}
            end

            table.insert(loadedSpawnList.cell[cellDescription],spawnEntry)
            tes3mp.LogMessage(enumerations.log.INFO,"SpawnAdmin: "..logicHandler.GetChatName(pid).." added "..id.." in " ..cellDescription.." to loaded spawns")
            Players[pid]:Message(color.Green .. "Added "..id.." in " ..cellDescription.." to loaded spawns\n")
        else
            Players[pid]:Message(color.Red .."Invalid command usage, use /slh "..cmd[1].." for usage\n")
        end
    end
end

--ex usage /lsl newTable.json
function spawnAdmin.loadSpawnList(pid,cmd)
    if Players[pid].data.settings.staffRank >= spawnConfig.staffRankReq then
        if cmd[2] ~= nil then
            local data = jsonInterface.load("custom/spawnData/"..cmd[2])
            if data == nil then
                Players[pid]:Message(color.Red .. "Spawn List does not exist: "..cmd[2].."\n")
            else
                loadedSpawnList = tableHelper.deepCopy(data)
                Players[pid]:Message(color.Green .. "Loaded spawn list: " ..cmd[2].."\n")
                tes3mp.LogMessage(enumerations.log.INFO,"SpawnAdmin: "..logicHandler.GetChatName(pid).." loaded "..cmd[2].." into active spawn list")
            end
        else
            Players[pid]:Message(color.Red .."Requires name of json table to load. Example: /lsl example.json\n")
        end
    end
end

--ex usage /ssl example.json
function spawnAdmin.saveList(pid,cmd)
    if Players[pid].data.settings.staffRank >= spawnConfig.staffRankReq then
        if cmd[2] ~= nil then
            if loadedSpawnList ~= nil then
                jsonInterface.save("custom/spawnData/"..cmd[2],loadedSpawnList)
                Players[pid]:Message(color.Green .. "Saved spawn list: " ..cmd[2].."\n")
                tes3mp.LogMessage(enumerations.log.INFO,"SpawnAdmin: "..logicHandler.GetChatName(pid).." saved loaded spawn list as "..cmd[2])
            else
                Players[pid]:Message(color.Red .. "Did not save spawn list "..cmd[2].." because it does not exist.\n")
            end
        else
            Players[pid]:Message(color.Red .."Requires name to save the table as. Example: /ssl example.json\n")
        end
    end
end

function spawnAdmin.helpCommand(pid,cmd)
    if Players[pid].data.settings.staffRank >= spawnConfig.staffRankReq then
        local message = ""
        if cmd[2] ~= nil then
            if cmd[2] == "as" or cmd[2] == "addspawn" then
                message = color.Purple .. "/as or /addspawn Usage:\n"
                message = message .. "/as <p/place/s/spawn> <r/refId/t/template> <id>\n"
                message = message .. color.White .. "--<p/place/s/spawn> defines packet type of entry, objects must be placed while npcs/creatures must be spawned.\n"
                message = message .. "--<r/refId/t/template> whether you want this spawn to use a template or a refId.\n"
                message = message .. "--<id> the refId or templateName to use.\n"
            elseif cmd[2] == "lsl" or cmd[2] == "loadspawnlist" then
                message = color.Purple .. "/lsl or /loadspawnlist Usage:\n"
                message = message .. "/lsl <table name>\n"
                message = message .. color.White .. "--<table name> .json table you want to load, if the table does not exist creates it.\n"
            elseif cmd[2] == "ssl" or cmd[2] == "savespawnlist" then
                message = color.Purple .. "/ssl or /savespawnlist Usage:\n"
                message = message .. "/ssl <table name>\n"
                message = message .. color.White .. "--<table name> what the active spawnlist is saved as. Does not need to be the same name as the loaded table.\n"
            end
        else
            message = color.Purple .. "Use /slh or /spawnlisthelp with a command name for more detail on each command\n"
            message = message .. "/lsl or /loadspawnlist\n" .. color.White .. "--Loads existing spawn list from json file or creates new one\n"
            message = message .. color.Purple .. "/as or /addspawn\n" .. color.White .. "--Add spawn at current player location to loaded list\n"
            message = message .. color.Purple .. "/ssl or /savespawnlist\n" .. color.White .. "--Save active spawn list to file\n"
        end
        Players[pid]:Message(message)
    end
end

customCommandHooks.registerCommand("as",spawnAdmin.addSpawn)
customCommandHooks.registerCommand("addspawn",spawnAdmin.addSpawn)
customCommandHooks.registerCommand("lsl",spawnAdmin.loadSpawnList)
customCommandHooks.registerCommand("loadspawnlist",spawnAdmin.loadSpawnList)
customCommandHooks.registerCommand("ssl",spawnAdmin.saveList)
customCommandHooks.registerCommand("savespawnlist",spawnAdmin.saveList)
customCommandHooks.registerCommand("spawnlisthelp",spawnAdmin.helpCommand)
customCommandHooks.registerCommand("slh",spawnAdmin.helpCommand)

return spawnAdmin