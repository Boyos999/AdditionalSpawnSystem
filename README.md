# Additional Spawn System
This script is a work in progress. Script to define additional spawns on a cell, refId, or uniqueIndex.

To Install:

1. Download the project folder and put it in scripts/custom, you should have an "AdditionalSpawnSystem" folder in custom now

2. Move the spawnData folder to data/custom

3. In customScripts.lua add the following require statement
```
    spawnSystem = require("custom.AdditionalSpawnSystem.spawnSystem.lua")
```

# Configuration
By default this script won't do anything, it is designed to read json files formatted like in the exampleSpawns.json. In spawnConfig.lua you can define which json files you want to include in your spawn tables, as well as define how you want those spawns to be merged with other configs. Read the comments for the config settings for more details.

# Included Spawn Tables
- exampleSpawns.json
  - Everything in this table is designed to be seen in seyda need, for quick testing/previewing
  - Duplicates imperial guards & mudcrabs
  - Adds some protection for Arrille
  - Spawns mudcrabs and imperial guards in a couple shacks in seyda need
- exampleTwo.json
  - Similar to exampleSpawns, designed for testing/preview of merge/overwrite
- creatureDuplication.json
  - Duplicate spawns of generic creature types
