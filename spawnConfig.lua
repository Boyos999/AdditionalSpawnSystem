spawnConfig = {}

--[[
Add spawn tables to this list to have their spawn's included
-name: json table file name in data/custom/spawnData
-mergeType: determines how the objects in the table are merged with previous tables
    0 = Will always overwrite any previous tables' spawns
    1 = Will merge spawns with previous tables' spawns
    2 = Will Never overwrite previous tables' spawns

]]
spawnConfig.spawnTables = {
    { name = "creatureDuplication.json", mergeType = 0 },
    { name = "creatureDuplicationTamrielData.json", mergeType = 0 },
    { name = "enhancedEncounters.json", mergeType = 0 },
    { name = "exampleRespawns.json", mergeType = 0 }
}


--Interval by which any spawns with "respawn" set are checked
spawnConfig.globalRespawnInterval = 30

--Whether to delete corpses when respawning actors
spawnConfig.respawnCleanCorpse = true

--If set to true the refId & uniqueIndex spawns will also spawn on actors spawned via
--the cell spawn list.
spawnConfig.actorSpawnOnCellSpawn = false

--Multiplier for # of actors spawned if the entry on the spawn table has useMult = true
--Can be a decimal value but rounds down to nearest integer, this can result in 0 spawns
--Split into exterior and interior spawn multipliers since high multipliers in exteriors
--cause significant performance impact
spawnConfig.extSpawnMult = 3
spawnConfig.intSpawnMult = 3

--Time in ms between when OnActorList is called and when actor positions are saved
--for spawns, this is needed because it takes time for position packets to be sent
spawnConfig.actorSpawnTimer = 500

--Minimum required staff rank to use spawnAdmin commands
spawnConfig.staffRankReq = 2

--Vanilla Classes (only playable classes included by default)
spawnConfig.class = {"acrobat","agent","archer","assassin","barbarian","bard",
                     "battlemage","crusader","healer","knight","mage","monk",
                     "nightblade","pilgrim","rogue","scout","sorcerer","spellsword",
                     "thief","warrior","witchhunter"}

--Vanilla Data on npc appearances
spawnConfig.npcInfo = jsonInterface.load("custom/spawnVanillaData/npcInfo.json")

--Vanilla races
spawnConfig.race = {"argonian","breton","dark elf","high elf","imperial","khajiit","nord","orc","redguard","wood elf"}

--Vanilla genders
spawnConfig.gender = {"female","male"}

--Level range if no level is declared
spawnConfig.level = {1,30}

--Settings that will be filled in randomly if not declared
spawnConfig.npcRequired = {"name","level","class","race","gender","head","hair"}

--[[
=====================================================================
Spawn Tables Spec
=====================================================================
{
    "cell": {
        <cell id>:[
            {
                "template":<string>,                                --Required if not refId
                "refId":<string>,                                   --Required if not template
                "count":<int>,                                      --Required
                "useMult":<bool>,
                "respawn":<int>,                                    # of seconds before respawn, if not set respawns on cell reset
                "packetType":<spawn|place>,                         --Required
                "location":{                                        --Required
                    "posX":<number>,"posY":<number>,"posZ":<number>,
                    "rotX":<number>,"rotY":<number>,"rotZ":<number>
                }
            }
        ]
    },
    "refId": {
        <actor refId>:[
            {
                "template":<string>,                                --Required if not refId
                "refId":<string>,                                   --Required if not template
                "count":<int>,                                      --Required
                "useMult":<bool>
            }
        ]
    },
    "uniqueIndex": {
        <actor uniqueIndex>:[
            {
                "template":<string>,                                --Required if not refId
                "refId":<string>,                                   --Required if not template
                "count":<int>,                                      --Required
                "useMult":<bool>
            }
        ]
    },
    "npcTemplates": {
        <template name>:{                                           --All values except name and gender can be arrays,
            "aiAlarm":<0-100>,                                      --one item from the array will be randomly chosen    
            "aiFight":<0-100>,                                      --unassigned required values will be randomized
            "aiFlee":<0-100>,
            "aiServices":<flags>,
            "autoCalc":<0-1>,                                       --Only set to 0 if using baseId, defaults to 1
            "baseId":<npc refId>,
            "class":<string>,
            "faction":<string>,
            "gender":<string>,                                      --See npcInfo.json for possible values
            "hair":<string>,                                        --See npcInfo.json for possible values dependent on race
            "head":<string>,                                        --See npcInfo.json for possible values dependent on race
            "invTemplate":<inventory template name>,
            "level":<int>,
            "name":<string>,
            "race":<string>                                         --See npcInfo.json for possible values
            ...                                                     --Other settings in config.validRecordSettings.npc should work,
        }                                                           --but use at own risk
    },
    "creatureTemplates": {
        <template name>:{
            "baseId":<creature refId>,                              --Required
            "damageChop":{"min":<int>,"max":<int>},
            "invTemplate":<inventory template name>
            ...                                                     --Any other setting in config.validRecordSettings.creature
        }
    },
    "inventoryTemplates": {
        <template name>:[                                           --Each entry in the template array can be a string or array
            <item refId>,                                           --For arrays a random item from the array will be chosen
            [<item refId 1>,<item refId 2>,<item refId 3>],         --There can be as many entries as you want
            ...
        ]
    }
}
=====================================================================
]]