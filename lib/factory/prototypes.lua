local M = {}

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
    local EntityLib = require("__FactorissimoLib__/lib/factory/entity")
    local Alternatives = require("__FactorissimoLib__/lib/alternatives")

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
        -- Хабы платформы не упаковываются, они всегда "стартовый набор"
        if factory_data.type == "space-platform-hub" then return nil end

        local item_inst = table.deepcopy(base_prototypes.item_instantiated["factory"])
        item_inst.name = factory_data.name .. "-instantiated"
        item_inst.localised_name = {"item-name.factory-packed", {"entity-name." .. factory_data.name}}
        item_inst.icons = {{
            icon = factory_data.graphics.icon, 
            icon_size = factory_data.graphics.icon_size
        }}
        item_inst.place_result = factory_data.name
        item_inst.subgroup = factory_data.subgroup

        return item_inst
    end

    -- 4. Создание рецепта (Recipe)
    M.make_recipe = function(factory_data)
        if not factory_data.recipe then return nil end

        local recipe = table.deepcopy(base_prototypes.recipe)
        local item_name = get_item_name(factory_data)

        recipe.name = item_name
        recipe.ingredients = factory_data.recipe.ingredients
        recipe.results = {{type = "item", name = item_name, amount = 1}}
        recipe.enabled = false -- Обычно открывается технологией
        
        return recipe
    end

    -- 5. Создание технологии (Technology)
    M.make_technology = function(factory_data)
        if not factory_data.technology then return nil end
        
        local tech = table.deepcopy(base_prototypes.technology)
        local item_name = get_item_name(factory_data)

        tech.name = factory_data.technology.name
        tech.icon = factory_data.technology.icon
        tech.icon_size = factory_data.technology.icon_size
        tech.prerequisites = factory_data.technology.prerequisites

        -- Настройка стоимости исследования
        tech.unit = {
            count = factory_data.technology.count,
            time = factory_data.technology.time,
            ingredients = factory_data.technology.ingredients
        }
        
        -- Эффект: открытие рецепта
        tech.effects = {{
            type = "unlock-recipe", 
            recipe = item_name
        }}
        
        return tech
    end
end

return M