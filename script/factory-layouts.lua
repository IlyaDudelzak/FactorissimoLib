local Layouts = {}

-- Хранилище сгенерированных лайоутов (в рантайме попадет в storage)
Layouts.generators = {}

local north = defines.direction.north
local east = defines.direction.east
local south = defines.direction.south
local west = defines.direction.west
local opposite = {[north] = south, [east] = west, [south] = north, [west] = east}

-- Вспомогательная функция для создания коннекшена (внутренняя)
local function make_connection(id, outside_x, outside_y, inside_x, inside_y, direction_out, quality)
    return {
        id = id,
        outside_x = outside_x,
        outside_y = outside_y,
        inside_x = inside_x,
        inside_y = inside_y,
        direction_in = opposite[direction_out],
        direction_out = direction_out,
        quality = quality or 1 -- По умолчанию обычное качество
    }
end

-- Генератор соединений на основе данных
local function generate_auto_connections(config)
    local connections = {}
    local inside_half = config.inside_size / 2
    local outside_half = config.outside_size / 2
    
    -- Базовое количество на сторону и бонус за уровень качества
    local base_count = config.connections_per_side or 4
    local quality_bonus = config.quality_bonus_per_side or 2

    -- Определяем параметры для каждой из 4-х сторон
    local sides = {
        {dir = north, ox = 0, oy = -outside_half - 0.5, ix = 0, iy = -inside_half - 0.5, axis = "x"},
        {dir = south, ox = 0, oy = outside_half + 0.5,  ix = 0, iy = inside_half + 0.5,  axis = "x"},
        {dir = east,  ox = outside_half + 0.5, oy = 0,  ix = inside_half + 0.5, iy = 0,  axis = "y"},
        {dir = west,  ox = -outside_half - 0.5, oy = 0, ix = -inside_half - 0.5, iy = 0, axis = "y"}
    }

    for _, side in ipairs(sides) do
        -- Генерируем порты для каждого уровня качества (1-5)
        for q = 1, 5 do
            -- Формула: количество растет с уровнем качества
            local count = base_count + (q - 1) * quality_bonus
            
            for i = 1, count do
                -- Уникальный ID: сторона_качество_номер
                local id = string.format("%s_%d_%d", side.dir, q, i)
                
                -- Рассчитываем смещение портов вдоль стены (от -0.5 до 0.5)
                -- Используем (i / (count + 1)) для равномерного распределения без краев
                local shift = (i / (count + 1)) - 0.5
                local offset_out = config.outside_size * shift
                local offset_in = config.inside_size * shift
                
                local cx_out, cy_out = side.ox, side.oy
                local cx_in, cy_in = side.ix, side.iy
                
                if side.axis == "x" then
                    cx_out = cx_out + offset_out
                    cx_in = cx_in + offset_in
                else
                    cy_out = cy_out + offset_out
                    cy_in = cy_in + offset_in
                end
                
                connections[id] = make_connection(id, cx_out, cy_out, cx_in, cy_in, side.dir, q)
            end
        end
    end
    return connections
end

-- Тот самый генератор тайлов из строки "+" (твоя мозаика)
function Layouts.generate_mosaic_tiles(mosaic, offset_x, offset_y)
    local tiles = {}
    local pattern = mosaic.pattern
    if not pattern then return tiles end
    
    local start_x = mosaic.x1 + offset_x
    local start_y = mosaic.y1 + offset_y
    
    for y, line in ipairs(pattern) do
        for x = 1, #line do
            if line:sub(x, x) == "+" then
                table.insert(tiles, {
                    name = mosaic.tile,
                    position = {start_x + (x - 1), start_y + (y - 1)}
                })
            end
        end
    end
    return tiles
end

-- ГЛАВНАЯ ФУНКЦИЯ: Регистрация новой фабрики в библиотеке
function Layouts.register_factory_type(config)
    local name = config.name
    local inside_size = config.inside_size
    local half_inside = inside_size / 2
    
    -- Генерируем имена тайлов на основе цвета из конфига
    local r, g, b = math.floor(config.color.r * 255), math.floor(config.color.g * 255), math.floor(config.color.b * 255)
    local wall_name = "factory-wall-color-" .. r .. "-" .. g .. "-" .. b
    local floor_name = "factory-floor-color-" .. r .. "-" .. g .. "-" .. b

    local layout = {
        name = name,
        tier = config.tier,
        inside_size = inside_size,
        outside_size = config.outside_size,
        inside_door_x = 0,
        inside_door_y = half_inside + 1,
        outside_door_x = 0,
        outside_door_y = (config.outside_size / 2),
        
        rectangles = {
            {x1 = -half_inside - 1, x2 = half_inside + 1, y1 = -half_inside - 1, y2 = half_inside + 1, tile = wall_name},
            {x1 = -half_inside, x2 = half_inside, y1 = -half_inside, y2 = half_inside, tile = floor_name},
            {x1 = -2, x2 = 2, y1 = half_inside, y2 = half_inside + 3, tile = "factory-entrance"},
        },
        
        -- Генерация соединений
        connections = generate_auto_connections(config),
        
        mosaics = config.pattern_data or {}
    }

    Layouts.generators[name] = layout
    
    if storage and storage.layout_generators then
        storage.layout_generators[name] = layout
    end
end

return Layouts