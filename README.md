# Additional Spawn System
This script is a work in progress. Script to define additional spawns on a cell, refId, or uniqueIndex.

To Install:

1. Download the project folder and put it in scripts/custom, you should have an "AdditionalSpawnSystem" folder in custom now

2. Move the spawnData and spawnVanillaData folders to data/custom

3. In customScripts.lua add the following require statement
```
    spawnSystem = require("custom.AdditionalSpawnSystem.spawnSystem")
    spawnAdmin = require("custom.AdditionalSpawnSystem.spawnAdmin")
```

# Configuration
This script is designed to read json files formatted like in the exampleSpawns.json. In spawnConfig.lua you can define which json files you want to include in your spawn tables, as well as define how you want those spawns to be merged with other configs. Read the comments for the config settings for more details. By default creature duplication and enhanced encounters are enabled

spawnAdmin includes some chat commands to add spawn entries on the player's current location, use /slh or /spawnlisthelp in-game for more info

*WARNING* Large numbers of additional spawns will result in reduced performance.

# Respawning actors/objects
If you set a value for "respawn" in one of the spawndata jsons those spawns will be respawned outside of cell resets on the given interval, this can only be set on spawns in the "cell" table. The `spawnConfig.globalRespawnInterval` setting in spawnConfig.lua sets the interval in seconds by which respawns are checked. See `exampleRespawns.json` for examples of how to use this

*WARNING* Changing spawnlists that use respawns without resetting cells can potentially cause issues

# Included Spawn Tables
- example\*.json
  - Everything in these tables is designed to be seen in seyda neen, for testing/showcasing
  - These tables are not suited to actually playing the game with
- creatureDuplication.json
  - Duplicate spawns of generic creature types
- creatureDuplicationTamrielData.json
  - Duplicate spawns of generic creatures in Tamriel Data v8.0 (combined assets for PT & TR)
- highSecurity.json
  - Duplicate guard spawns
- enhancedEncounters
  - Spawn additional npcs in various to make them more suitable to 2-4 player coop
  - Note: many locations that were fine with just duplicated generic spawns were left untouched
  - Intended to be used with creatureDuplication

# Future planned additions
1. Per spawnTable spawn multiplier
2. Better inventory handling (set "count" per item refId)
3. Loot lists usable in inventory templates
4. cellDelete table of unique indexes to delete on cell load

# Known Issues
1. Spawns on refIds/uniqueIndexes are on a delay, this is because it takes time for the packets with the actor locations to arrive so we know where to spawn them. The delay is configurable via the config, your results may vary
