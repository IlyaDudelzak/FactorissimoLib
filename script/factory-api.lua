local FactoryLib = require("lib.factory.lib")
local layout_generator = require("lib.factory.layout-generator")

local factory_api = {}

local BUILDING_TYPE = "storage-tank" -- Убедись, что твои здания в прототипах имеют этот тип!

function factory_api.create_layout(name, quality) 
    if not name or not quality then return end
    local fd = FactoryLib.get_factory_data(name)
    if not fd then return end
    return layout_generator.generate_layout(fd, quality)
end

-- Исправленные функции работы с памятью мода
factory_api.get_storage = function(path)
    if not path then return storage end
    local g = storage
    for _, point in ipairs(path) do
        g = g[point]
    end
    return g
end

factory_api.set_storage = function(path, v)
    local g = storage
    for i = 1, #path - 1 do
        g = g[path[i]]
    end
    g[path[#path]] = v
end

factory_api.get_factory_by_entity = function(entity)
    if entity == nil then return nil end
    return storage.factories_by_entity[entity.unit_number]
end

factory_api.get_factory_by_building = function(entity)
    local factory = storage.factories_by_entity[entity.unit_number]
    if factory == nil then
        game.print("ERROR: Unbound factory building: " .. entity.name)
    end
    return factory
end

factory_api.has_layout = function(name)
    if not name then return false end
    name = name:gsub("%-instantiated", "")
    return FactoryLib.is_factory(name)
end

-- Делаем функцию доступной глобально, как в старом моде
_G.has_layout = factory_api.has_layout

factory_api.find_factory_by_area = function(params)
    local surface = params.surface
    local position = params.position
    local area = params.area

    local entities = surface.find_entities_filtered {position = position, area = area, type = BUILDING_TYPE}
    for _, entity in pairs(entities) do
        if factory_api.has_layout(entity.name) then 
            return factory_api.get_factory_by_building(entity) 
        end
    end
    return nil
end

factory_api.find_surrounding_factory = function(surface, position)
    if not (surface and storage.surface_factories) then return nil end
    local factories = storage.surface_factories[surface.index]
    if factories == nil then return nil end
    
    -- Логика координат Factorissimo (сетка 16x32 чанка)
    local x = math.floor(0.5 + position.x / (16 * 32))
    local y = math.floor(0.5 + position.y / (16 * 32))
    if (x > 7 or x < 0) then return nil end
    return factories[8 * y + x + 1]
end

-- ... остальные функции (create_layout, add_layout и т.д.) перенеси сюда аналогично ...

-- Регистрация интерфейса для других модов
remote.add_interface("factorissimo", factory_api)

return factory_api