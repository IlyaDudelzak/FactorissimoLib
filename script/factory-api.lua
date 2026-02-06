local FactoryLib = require("lib.factory.lib")
local layout_generator = require("lib.factory.layout-generator")

local factory_api = {}
local BUILDING_TYPE = "storage-tank" 

-- Вспомогательная функция (обязательно должна быть объявлена до использования)
factory_api.has_layout = function(name)
    if not name then return false end
    name = name:gsub("%-instantiated", "")
    return FactoryLib.is_factory(name)
end
_G.has_layout = factory_api.has_layout

factory_api.get_factory_by_entity = function(entity)
    if not (entity and entity.valid) then return nil end
    return storage.factories_by_entity[entity.unit_number]
end

factory_api.get_factory_by_building = function(entity)
    local factory = storage.factories_by_entity[entity.unit_number]
    if factory == nil then
        -- Полезно для дебага, чтобы знать где именно стоит "битое" здание
        game.print("ERROR: Unbound factory building: " .. entity.name .. " at " .. entity.position.x .. "," .. entity.position.y)
    end
    return factory
end

-- ТА САМАЯ ФУНКЦИЯ, КОТОРОЙ НЕ ХВАТАЛО (для electricity.lua)
factory_api.find_factories_by_area = function(params)
    local surface = params.surface
    local area = params.area
    if not (surface and surface.valid) then return {} end

    local factories = {}
    local entities = surface.find_entities_filtered {area = area, type = BUILDING_TYPE}
    for _, entity in pairs(entities) do
        if factory_api.has_layout(entity.name) then
            local factory = factory_api.get_factory_by_building(entity)
            if factory then table.insert(factories, factory) end
        end
    end
    return factories
end

-- Находит одну фабрику в точке
factory_api.find_factory_by_area = function(params)
    local surface = params.surface
    local area = params.area or {{params.position.x - 0.1, params.position.y - 0.1}, {params.position.x + 0.1, params.position.y + 0.1}}
    
    local entities = surface.find_entities_filtered {area = area, type = BUILDING_TYPE}
    for _, entity in pairs(entities) do
        if factory_api.has_layout(entity.name) then 
            return factory_api.get_factory_by_building(entity) 
        end
    end
    return nil
end

-- ИСПРАВЛЕННЫЙ ПОИСК В СПИРАЛИ
-- Поскольку мы используем спираль, старая формула (8*y+x) не работает.
-- Самый надежный способ — просто искать через storage.surface_factories
factory_api.find_surrounding_factory = function(surface, position)
    if not (surface and storage.surface_factories) then return nil end
    local factories_on_surface = storage.surface_factories[surface.index]
    if not factories_on_surface then return nil end
    
    -- Ищем, в какой "квадрат" сетки 16x32 чанков попадает позиция
    local FACTORISSIMO_CHUNK_SPACING = 16
    local GRID_STEP = FACTORISSIMO_CHUNK_SPACING * 32 -- 512 тайлов
    
    local x = math.floor(0.5 + position.x / GRID_STEP)
    local y = math.floor(0.5 + position.y / GRID_STEP)

    -- Просто перебираем фабрики на этой поверхности. 
    -- В спирали их обычно не тысячи, так что это быстро и на 100% точно.
    for _, factory in pairs(factories_on_surface) do
        if math.floor(0.5 + factory.inside_x / GRID_STEP) == x and 
           math.floor(0.5 + factory.inside_y / GRID_STEP) == y then
            return factory
        end
    end
    return nil
end

factory_api.is_factorissimo_surface = function(surface)
    if not surface then return false end
    local surface_index = (type(surface) == "table") and surface.index or surface
    if type(surface) == "string" then
        local s = game.get_surface(surface)
        surface_index = s and s.index
    end
    return surface_index and storage.surface_factories[surface_index] ~= nil
end

-- Остальное
factory_api.create_layout = function(name, quality) 
    local fd = FactoryLib.get_factory_data(name)
    if not fd then return nil end
    return layout_generator.generate_layout(fd, quality)
end

factory_api.create_factory_tiles = function(fd)
    if not fd then return end
    return layout_generator.make_tiles(fd)
end

-- Регистрация
remote.add_interface("factorissimo", factory_api)

return factory_api