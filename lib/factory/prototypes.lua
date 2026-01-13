local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local EntityLib = require("__FactorissimoLib__/lib/factory/entity")

local M = {}

-- Вспомогательная функция для суффиксов
local function get_item_name(factory_data)
    local suffix = (factory_data.type == "space-platform-hub") and "-starter-pack" or ""
    return factory_data.name .. suffix
end

-- 1. Создание сущности здания (вызов из EntityLib)
M.make_entity = function(factory_data)
    return EntityLib.make_building(factory_data)
end

-- 2. Создание основного предмета (Item)
M.make_item = function(factory_data)
    local item = table.deepcopy(base_prototypes.item[factory_data.type])
    item.name = get_item_name(factory_data)
    item.icon = factory_data.graphics.icon
    item.icon_size = factory_data.graphics.icon_size
    item.place_result = factory_data.name
    item.order = "a[" .. factory_data.tier .. "]"
    item.subgroup = factory_data.subgroup
    return item
end

-- 3. Создание упакованной фабрики (Instantiated Item)
M.make_instantiated_item = function(factory_data)
    if factory_data.type == "space-platform-hub" then return nil end
    
    local item_inst = table.deepcopy(base_prototypes.item_instantiated["factory"])
    item_inst.name = get_item_name(factory_data) .. "-instantiated"
    item_inst.localised_name = {"item-name.factory-packed", {"entity-name." .. factory_data.name}}
    item_inst.icons = {{icon = factory_data.graphics.icon, icon_size = factory_data.graphics.icon_size}}
    item_inst.place_result = factory_data.name
    item_inst.subgroup = factory_data.subgroup
    return item_inst
end

-- 4. Создание рецепта
M.make_recipe = function(factory_data)
    if not factory_data.recipe then return nil end
    
    local recipe = table.deepcopy(base_prototypes.recipe)
    recipe.name = get_item_name(factory_data)
    recipe.ingredients = factory_data.recipe.ingredients
    recipe.results = {{type = "item", name = recipe.name, amount = 1}}
    return recipe
end

-- 5. Создание технологии
M.make_technology = function(factory_data)
    if not factory_data.technology then return nil end
    
    local tech = table.deepcopy(base_prototypes.technology)
    local item_name = get_item_name(factory_data)
    
    tech.name = factory_data.technology.name
    tech.icon = factory_data.technology.icon
    tech.icon_size = factory_data.technology.icon_size
    tech.prerequisites = factory_data.technology.prerequisites
    tech.unit = {
        count = factory_data.technology.count,
        time = factory_data.technology.time,
        ingredients = factory_data.technology.ingredients
    }
    tech.effects = {{type = "unlock-recipe", recipe = item_name}}
    return tech
end

return M