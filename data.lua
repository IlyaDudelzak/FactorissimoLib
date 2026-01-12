local TilesLib = require("__factorissimo-3-space-factory__/lib/tiles")
local EntityModule = require("__factorissimo-3-space-factory__/lib/factory/entity")
local ItemModule = require("__factorissimo-3-space-factory__/lib/factory/item")
local RecipeModule = require("__factorissimo-3-space-factory__/lib/factory/recipe")
local TechModule = require("__factorissimo-3-space-factory__/lib/factory/technology")

local M = {}
M.factory_data = {}

local allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

M.add_factory = function(factory_data)
    if not factory_data or not factory_data.name then error("Factory name missing") end
    if not allowed_factory_types[factory_data.type] then error("Invalid type: " .. tostring(factory_data.type)) end

    -- Генерация имен тайлов на основе цвета
    factory_data.wall_tile_name = TilesLib.createColoredTile("factory-wall", factory_data.color)
    factory_data.floor_tile_name = TilesLib.createColoredTile("factory-floor", factory_data.color)

    M.factory_data[factory_data.name] = factory_data
end

M.make_factory_prototypes = function(factory_data)
    local prototypes = {} 
    
    -- 1. Сущность
    table.insert(prototypes, EntityModule.make_building(factory_data))
    
    -- 2. Предметы
    table.insert(prototypes, ItemModule.make_item(factory_data))
    if factory_data.type ~= "space-platform-hub" then 
        table.insert(prototypes, ItemModule.make_item_instantiated(factory_data)) 
    end
    
    -- 3. Рецепт
    if factory_data.recipe then 
        table.insert(prototypes, RecipeModule.make_recipe(factory_data)) 
    end
    
    -- 4. Технология
    if factory_data.technology then 
        table.insert(prototypes, TechModule.make_technology(factory_data)) 
    end
    
    return prototypes
end

M.add_all_factory_prototypes = function(data_ptr)
    for _, factory_data in pairs(M.factory_data) do
        data_ptr:extend(M.make_factory_prototypes(factory_data))
    end
end

return M