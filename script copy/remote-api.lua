remote_api = {}

local BUILDING_TYPE = "storage-tank"

-- Утилитные функции для работы с global/storage (через пути)
remote_api.get_global = function(path)
    if not path then return storage end
    local g = storage
    for _, point in ipairs(path) do
        g = g[point]
    end
    return g
end

remote_api.set_global = function(path, v)
    local g = storage
    for i = 1, #path - 1 do
        g = g[path[i]]
    end
    g[path[#path]] = v
end

-- Поиск объекта фабрики по сущности Factorio
remote_api.get_factory_by_entity = function(entity)
    if entity == nil then return nil end
    return storage.factories_by_entity[entity.unit_number]
end

remote_api.get_factory_by_building = function(entity)
    local factory = storage.factories_by_entity[entity.unit_number]
    if factory == nil then
        -- Выводим ошибку, если здание не привязано к логике мода
        game.print("ERROR: Unbound factory building: " .. entity.name .. "@" .. entity.surface.name .. "(" .. entity.position.x .. ", " .. entity.position.y .. ")")
    end
    return factory
end

-- Поиск фабрики в области (используется при входе игрока)
remote_api.find_factory_by_area = function(params)
    local surface = params.surface
    local position = params.position
    local area = params.area

    for _, entity in pairs(surface.find_entities_filtered {position = position, area = area, type = BUILDING_TYPE}) do
        if has_layout(entity.name) then 
            return remote_api.get_factory_by_building(entity) 
        end
    end
    return nil
end

-- Поиск фабрики по позиции на поверхности (используется при выходе)
-- Использует математику сетки (8x8 чанков или аналогично)
remote_api.find_surrounding_factory = function(surface, position)
    local factories = storage.surface_factories[surface.index]
    if factories == nil then return nil end
    
    local x = math.floor(0.5 + position.x / (16 * 32))
    local y = math.floor(0.5 + position.y / (16 * 32))
    
    if (x > 7 or x < 0) then return nil end
    return factories[8 * y + x + 1]
end

-- Инстанцирование лайоута с учетом КАЧЕСТВА
remote_api.create_layout = function(name, quality)
    local layout_base = storage.layout_generators[name]
    if not layout_base then return nil end
    
    local layout = table.deepcopy(layout_base)
    local connections = {}
    
    -- Фильтруем порты: оставляем только те, что соответствуют качеству здания или ниже
    local quality_level = quality and quality.level or 0
    for id, connection in pairs(layout.connections) do
        if (connection.quality or 0) <= quality_level then
            connections[id] = connection
        end
    end
    layout.connections = connections

    return layout
end

-- Управление списком доступных лайоутов
remote_api.add_layout = function(layout)
    storage.layout_generators = storage.layout_generators or {}
    storage.layout_generators[layout.name] = layout
end

remote_api.has_layout = function(name)
    -- Убираем суффикс инстанцирования, если он есть
    name = name:gsub("%-instantiated", "")
    return storage.layout_generators[name] ~= nil
end

-- Регистрируем в глобальной области для быстрого доступа
_G.has_layout = remote_api.has_layout

-- Проверка, является ли поверхность внутренней поверхностью фабрики
remote_api.is_factorissimo_surface = function(surface)
    if not surface then return false end
    local surface_index
    local surface_type = type(surface)

    if surface_type == "number" then
        surface_index = surface
    elseif surface_type == "string" then
        local s = game.get_surface(surface)
        if not s then return false end
        surface_index = s.index
    else
        surface_index = surface.index
    end

    return not not storage.surface_factories[surface_index]
end

-- Регистрация интерфейса для взаимодействия с другими модами
remote.add_interface("factorissimo", remote_api)