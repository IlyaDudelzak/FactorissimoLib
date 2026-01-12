# API Integration Summary

Example of a complete setup in your mod:

```lua
local f_lib = require("__my-library-name__/library")

-- 1. Register a patch for an existing factory
f_lib.alternatives.add_patch("small-factory", { 
    max_health = 5000 
}, "mod", "space-age", 100)

-- 2. Define a new factory
f_lib.factory_manager.add_factory({
    name = "small-factory",
    type = "factory",
    tier = 1,
    outside_size = 7,
    inside_size = 20,
    color = {r=0.7, g=0.2, b=0.2},
    -- ... other data
})

-- 3. Push to Factorio data
f_lib.factory_manager.add_all_factory_prototypes(data)
f_lib.tile_manager.addToData()