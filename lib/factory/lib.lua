local TilesLib = require("__factorissimo-3-space-factory__/lib/tiles")
local LayoutsLib = require("__factorissimo-3-space-factory__/script/factory-layouts")
local base_prototypes = require("__factorissimo-3-space-factory__/lib/base-prototypes")

local M = {}
M.factory_data = {}

-- [[ Вспомогательные функции ]]
local function make_box(size, offset)
    local r = size / 2 - offset
    return {{-r, -r}, {r, r}}
end

local function get_factory_item_suffix(factory_data)
    if factory_data.type == "space-platform-hub" then return "-starter-pack" end
    return ""
end

local allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

-- [[ ОСНОВНОЕ API БИБЛИОТЕКИ ]]

-- 1. Регистрация данных фабрики
M.add_factory = function(factory_data)
    if not factory_data or not factory_data.name then error("Factory name missing") end
    if not allowed_factory_types[factory_data.type] then error("Invalid type: " .. tostring(factory_data.type)) end

    -- Генерируем тайлы на основе цвета (использует твою функцию M.createColoredTile)
    factory_data.wall_tile_name = TilesLib.createColoredTile("factory-wall", factory_data.color)
    factory_data.floor_tile_name = TilesLib.createColoredTile("factory-floor", factory_data.color)

    -- РЕГИСТРАЦИЯ ЛАЙОУТА (для remote_api и рантайма)
    -- Эта функция теперь внутри LayoutsLib сама создаст все connections и rectangles
    LayoutsLib.register_factory_type(factory_data)

    M.factory_data[factory_data.name] = factory_data
end

-- 2. Создание прототипов (Building, Item, Recipe, Tech)
M.make_factory_prototypes = function(factory_data)
    local prototypes = {} 
    local name = factory_data.name
    
    -- Entity (Здание)
    local prototype = table.deepcopy(base_prototypes.entity[factory_data.type])
    prototype.name = name
    prototype.icon = factory_data.graphics.icon
    prototype.icon_size = factory_data.graphics.icon_size
    prototype.map_color = factory_data.color
    prototype.collision_box = make_box(factory_data.outside_size, 0.2)
    prototype.selection_box = make_box(factory_data.outside_size, 0.2)
    prototype.max_health = factory_data.max_health or (math.pow(2.5, factory_data.tier) * 2000)
    
    if factory_data.type == "factory" then
        prototype.minable.result = name .. "-instantiated"
        prototype.placeable_by.item = name
        prototype.pictures = factory_data.graphics.pictures
    elseif factory_data.type == "space-platform-hub" then
        prototype.weight = 1000 * factory_data.outside_size * factory_data.outside_size
    end
    table.insert(prototypes, prototype)

    -- Item (Предмет для установки)
    local item_suffix = get_factory_item_suffix(factory_data)
    local item = table.deepcopy(base_prototypes.item[factory_data.type])
    item.name = name .. item_suffix
    item.icon = factory_data.graphics.icon
    item.icon_size = factory_data.graphics.icon_size
    item.place_result = name
    item.order = "a[" .. factory_data.tier .. "]"
    item.subgroup = factory_data.subgroup or "factorissimo-factories-tier-" .. factory_data.tier
    table.insert(prototypes, item)

    -- Item Instantiated (Упакованная фабрика)
    if factory_data.type ~= "space-platform-hub" then 
        local item_inst = table.deepcopy(base_prototypes.item_instantiated["factory"])
        item_inst.name = name .. "-instantiated"
        item_inst.localised_name = {"item-name.factory-packed", {"entity-name." .. name}}
        item_inst.icons = {{icon = factory_data.graphics.icon, icon_size = factory_data.graphics.icon_size}}
        item_inst.place_result = name
        item_inst.subgroup = item.subgroup
        table.insert(prototypes, item_inst) 
    end

    -- Recipe (Рецепт)
    if factory_data.recipe then 
        local recipe = table.deepcopy(base_prototypes.recipe)
        recipe.name = name .. item_suffix
        recipe.ingredients = factory_data.recipe.ingredients
        recipe.results = {{type = "item", name = name .. item_suffix, amount = 1}}
        table.insert(prototypes, recipe)
    end

    -- Technology (Технология)
    if factory_data.technology then 
        local tech = table.deepcopy(base_prototypes.technology)
        tech.name = factory_data.technology.name
        tech.icon = factory_data.technology.icon
        tech.icon_size = factory_data.technology.icon_size
        tech.prerequisites = factory_data.technology.prerequisites
        tech.unit.count = factory_data.technology.count
        tech.unit.time = factory_data.technology.time
        tech.unit.ingredients = factory_data.technology.ingredients
        tech.effects = {{type = "unlock-recipe", recipe = name .. item_suffix}}
        table.insert(prototypes, tech)
    end

    return prototypes
end

-- 3. Массовое добавление в data.raw (вызывать в data.lua)
M.add_all_factory_prototypes = function()
    local all_prototypes = {}
    for _, factory_data in pairs(M.factory_data) do
        local pros = M.make_factory_prototypes(factory_data)
        for _, p in ipairs(pros) do table.insert(all_prototypes, p) end
    end
    data:extend(all_prototypes)
    
    -- Вызываем создание тайлов в data.raw
    TilesLib.addToData()
end

return M