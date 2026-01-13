local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local util = require("util") -- Встроенная библиотека Factorio для JSON

local M = {}

-- [[ Вспомогательные функции ]]

local function make_box(size, offset)
    local r = size / 2 - offset
    return {{-r, -r}, {r, r}}
end

-- Функция фильтрации: оставляем только то, что нужно Runtime логике
-- Это экономит память и защищает от ошибок сериализации функций
local function get_metadata_json(factory_data)
    local metadata = {
        tier = factory_data.tier,
        inside_size = factory_data.inside_size,
        outside_size = factory_data.outside_size,
        conditioned = factory_data.conditioned,
        pattern = factory_data.pattern,
        connections_per_side = factory_data.connections_per_side,
        -- Сохраняем цвет как простую таблицу
        color = {
            r = factory_data.color.r,
            g = factory_data.color.g,
            b = factory_data.color.b
        }
    }
    return util.table_to_json(metadata)
end

-- [[ ОСНОВНОЕ API ]]

M.make_building = function(factory_data)
    local name = factory_data.name
    local prototype = table.deepcopy(base_prototypes.entity[factory_data.type])
    
    prototype.name = name
    prototype.icon = factory_data.graphics.icon
    prototype.icon_size = factory_data.graphics.icon_size
    prototype.map_color = factory_data.color
    prototype.collision_box = make_box(factory_data.outside_size, 0.2)
    prototype.selection_box = make_box(factory_data.outside_size, 0.2)
    prototype.max_health = factory_data.max_health or (math.pow(2.5, factory_data.tier) * 2000)
    
    -- СЕРИАЛИЗАЦИЯ МЕТАДАННЫХ
    -- Используем флаг "?" для скрытия JSON-строки от игрока
    prototype.localised_description = {
        "?", 
        {"entity-description." .. name}, -- Попытка найти описание в локализации
        {"", "Factorio Space Factory"},
        get_metadata_json(factory_data)  -- JSON данные во втором (запасном) слоте
    }
    
    if factory_data.type == "factory" then
        prototype.minable.result = name .. "-instantiated"
        prototype.placeable_by.item = name
        prototype.pictures = factory_data.graphics.pictures
    elseif factory_data.type == "space-platform-hub" then
        prototype.weight = 1000 * factory_data.outside_size * factory_data.outside_size
    end
    
    return prototype
end

return M