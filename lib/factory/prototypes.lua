local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local EntityLib = require("__FactorissimoLib__/lib/factory/entity")
local Alternatives = require("__FactorissimoLib__/lib/alternatives")

local M = {}

----------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------

-- Получаем актуальные данные фабрики с учетом всех патчей
local function get_fd(factory_data)
    return Alternatives.apply_alternatives("factory-data-" .. factory_data.name, factory_data)
end

-- Генерируем имя предмета (учитываем спец-суффиксы)
local function get_item_name(fd)
    local suffix = (fd.type == "space-platform-hub") and "-starter-pack" or ""
    return fd.name .. suffix
end

----------------------------------------------------------------
-- ОСНОВНЫЕ ФУНКЦИИ СОЗДАНИЯ
----------------------------------------------------------------

-- 1. Создание сущности здания (Entity)
M.make_entity = function(factory_data)
    -- EntityLib.make_building уже внутри себя вызывает Alternatives.apply_alternatives
    return EntityLib.make_building(factory_data)
end

-- 2. Создание основного предмета (Item)
M.make_item = function(factory_data)
    local fd = get_fd(factory_data)
    local item = table.deepcopy(base_prototypes.item[fd.type])
    
    item.name = get_item_name(fd)
    item.icon = fd.graphics.icon
    item.icon_size = fd.graphics.icon_size
    item.place_result = fd.name
    item.order = "a[" .. fd.tier .. "]"
    item.subgroup = fd.subgroup
    
    return item
end

-- 3. Создание упакованной фабрики (Instantiated Item)
M.make_instantiated_item = function(factory_data)
    local fd = get_fd(factory_data)
    
    -- Хабы платформы не упаковываются, они всегда "стартовый набор"
    if fd.type == "space-platform-hub" then return nil end
    
    local item_inst = table.deepcopy(base_prototypes.item_instantiated["factory"])
    item_inst.name = fd.name .. "-instantiated"
    item_inst.localised_name = {"item-name.factory-packed", {"entity-name." .. fd.name}}
    item_inst.icons = {{
        icon = fd.graphics.icon, 
        icon_size = fd.graphics.icon_size
    }}
    item_inst.place_result = fd.name
    item_inst.subgroup = fd.subgroup
    
    return item_inst
end

-- 4. Создание рецепта (Recipe)
M.make_recipe = function(factory_data)
    local fd = get_fd(factory_data)
    if not fd.recipe then return nil end
    
    local recipe = table.deepcopy(base_prototypes.recipe)
    local item_name = get_item_name(fd)
    
    recipe.name = item_name
    recipe.ingredients = fd.recipe.ingredients
    recipe.results = {{type = "item", name = item_name, amount = 1}}
    recipe.enabled = false -- Обычно открывается технологией
    
    return recipe
end

-- 5. Создание технологии (Technology)
M.make_technology = function(factory_data)
    local fd = get_fd(factory_data)
    if not fd.technology then return nil end
    
    local tech = table.deepcopy(base_prototypes.technology)
    local item_name = get_item_name(fd)
    
    tech.name = fd.technology.name
    tech.icon = fd.technology.icon
    tech.icon_size = fd.technology.icon_size
    tech.prerequisites = fd.technology.prerequisites
    
    -- Настройка стоимости исследования
    tech.unit = {
        count = fd.technology.count,
        time = fd.technology.time,
        ingredients = fd.technology.ingredients
    }
    
    -- Эффект: открытие рецепта
    tech.effects = {{
        type = "unlock-recipe", 
        recipe = item_name
    }}
    
    return tech
end

return M