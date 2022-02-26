spawnConfig = {}

--[[
Add spawn tables to this list to have their spawn's included
-name: json table file name in data/custom/spawnSystem
-mergeType: determines how the objects in the table are merged with previous tables
    0 = Will always overwrite any previous tables' spawns
    1 = Will merge spawns with previous tables' spawns
    2 = Will Never overwrite previous tables' spawns

]]
spawnConfig.spawnTables = {
    --{ name = "exampleSpawns.json", mergeType = 0 }
}

--If set to true the refId & uniqueIndex spawns will also spawn on actors spawned via
--the cell spawn list.
spawnConfig.actorSpawnOnCellSpawn = false

--Multiplier for # of actors spawned if the entry on the spawn table has useMult = true
--Can be a decimal value but rounds down to nearest integer, this can result in 0 spawns
spawnConfig.spawnMult = 1

--Time in ms between when OnActorList is called and when actor positions are saved
--for spawns, this is needed because it takes time for position packets to be sent
spawnConfig.actorSpawnTimer = 500

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
            "aiServices":<flags>
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
        }
    },
    "creatureTemplates": {},                                        --TODO
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