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
    { name = "exampleSpawns.json", mergeType = 0 }
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
