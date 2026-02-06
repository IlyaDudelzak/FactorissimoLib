local M = {}

local connections = require("lib.factory.connections")

local pattern_gen = require("lib.pattern-gen")

function M.make_space_line(number)
    local line = ""
    while true do 
        if #line == number then return line end
        line = line .. " "
    end
end

function M.bring_pattern_up(pattern, inside_size)
    if not pattern or #pattern == 0 then return nil end
    if #pattern > inside_size or #pattern[1] > inside_size then
        error("Pattern is bigger than inside size")
    end
    local h_diff = (inside_size - #pattern) / 2
    local w_diff = (inside_size - #pattern[1]) / 2
    local new_pattern = {}
    local empty_line = M.make_space_line(inside_size)
    local diff_line = M.make_space_line(w_diff)

    for y = 1, h_diff do
        new_pattern[#new_pattern + 1] = empty_line
    end

    for _, line in ipairs(pattern) do
        new_pattern[#new_pattern + 1] = diff_line .. line .. diff_line
    end

    for y = 1, h_diff do
        new_pattern[#new_pattern + 1] = empty_line
    end
    return new_pattern
end

function M.add_tile_mosaic(factory_data, tiles)
    -- Генерируем паттерн, уже подогнанный под размер комнаты
    local pattern = M.bring_pattern_up(pattern_gen.generate(factory_data.pattern), factory_data.inside_size)
    
    local h = #pattern
    local w = #pattern[1]
    
    -- Центрируем: если ширина 12, x_offset будет -6.
    local x_offset = -w / 2
    local y_offset = -h / 2
    
    local tile_name = "factory-floor-color-" .. 
        math.floor(factory_data.color.r * 255) .. "-" .. 
        math.floor(factory_data.color.g * 255) .. "-" .. 
        math.floor(factory_data.color.b * 255)

    local floor_name = "factory-floor"

    local i = #tiles
    
    -- Итерируемся строго по размеру массива паттерна
    for y = 1, h do
        local line = pattern[y]
        for x = 1, w do
            i = i + 1
            tiles[i] = {
                name = string.sub(line, x, x) == "+" and tile_name or floor_name, 
                position = {x - 1 + x_offset, y - 1 + y_offset}
            }
        end
    end
end

local function rotate_pos(x, y, side)
    if side == "s" then return {x = x, y = y} end
    if side == "n" then return {x = -x - 1, y = -y - 1} end
    if side == "e" then return {x = y, y = -x - 1} end
    if side == "w" then return {x = -y - 1, y = x} end
    return {x = x, y = y}
end

function M.add_entrance(factory_data, tiles)
    if not factory_data.door then return end
    
    local side = factory_data.door.side
    local extent = factory_data.inside_size / 2
    local i = #tiles
    
    local wall_tile = "factory-wall-color-" .. 
        math.floor(factory_data.color.r * 255) .. "-" .. 
        math.floor(factory_data.color.g * 255) .. "-" .. 
        math.floor(factory_data.color.b * 255)
    local entrance_tile = "factory-entrance-floor"

    -- Базовые координаты для ЮЖНОЙ стороны (S):
    -- Стенка находится на y = extent
    
    -- 1. Прямоугольник входа 4x3 (Центрирован: x от -2 до 1)
    -- Один ряд (dy=0) накладывается на линию стены, два ряда (dy=1,2) выходят наружу
    for dy = 0, 2 do
        for dx = -2, 1 do
            local p = rotate_pos(dx, extent + dy, side)
            i = i + 1
            tiles[i] = {name = entrance_tile, position = {p.x, p.y}}
        end
    end

    -- 2. Три тайла стены в каждую сторону от прямоугольника (на линии стены)
    -- Слева: -5, -4, -3. Справа: 2, 3, 4.
    local wall_offsets = {-5, -4, -3, 2, 3, 4}
    for _, dx in ipairs(wall_offsets) do
        local p = rotate_pos(dx, extent, side)
        i = i + 1
        tiles[i] = {name = wall_tile, position = {p.x, p.y}}
    end

    -- 3. Два тайла стены "вниз" (наружу), прилегая к прямоугольнику
    -- Слева от входа (x=-3) и справа (x=2) на глубину dy=1, dy=2
    for dy = 1, 2 do
        -- Левое "ушко"
        local p1 = rotate_pos(-3, extent + dy, side)
        i = i + 1
        tiles[i] = {name = wall_tile, position = {p1.x, p1.y}}
        
        -- Правое "ушко"
        local p2 = rotate_pos(2, extent + dy, side)
        i = i + 1
        tiles[i] = {name = wall_tile, position = {p2.x, p2.y}}
    end
end

function M.add_walls(factory_data, tiles)
    local size = factory_data.inside_size
    local extent = size / 2
    local tile_name = "factory-wall-color-" .. 
        math.floor(factory_data.color.r * 255) .. "-" .. 
        math.floor(factory_data.color.g * 255) .. "-" .. 
        math.floor(factory_data.color.b * 255)
    local connection_tile_name = "factory-connection-tile"
    
    local i = #tiles
    local door_side = factory_data.door and factory_data.door.side

    -- 1. Горизонтальные линии (Верх и Низ)
    for x = -extent - 1, extent do
        -- Верх (North)
        if not (door_side == "n" and x >= -5 and x <= 4) then
            i = i + 1
            tiles[i] = {name = tile_name, position = {x, -extent - 1}}
        end
        
        -- Низ (South)
        if not (door_side == "s" and x >= -5 and x <= 4) then
            i = i + 1
            tiles[i] = {name = tile_name, position = {x, extent}}
        end
    end

    -- 2. Вертикальные линии (Лево и Право)
    for y = -extent, extent - 1 do
        -- Лево (West)
        if not (door_side == "w" and y >= -5 and y <= 4) then
            i = i + 1
            tiles[i] = {name = tile_name, position = {-extent - 1, y}}
        end
        
        -- Право (East)
        if not (door_side == "e" and y >= -5 and y <= 4) then
            i = i + 1
            tiles[i] = {name = tile_name, position = {extent, y}}
        end
    end
end

function M.make_tiles(factory_data)
    local tiles = {}
    M.add_tile_mosaic(factory_data, tiles)
    M.add_walls(factory_data, tiles)
    M.add_entrance(factory_data, tiles) -- Добавляем вход в конце
    return tiles
end

-- layout_generators["factory-1"] = {
--     name = "factory-1",
--     tier = 1,
--     inside_size = 30,
--     outside_size = 10,
--     inside_door_x = 0,
--     inside_door_y = 16,
--     outside_door_x = 0,
--     outside_door_y = 4,
--     connections = {
--         w1 = make_connection("w1", -4.5, -2.5, -15.5, -9.5, west),
--         e1 = make_connection("e1", 4.5, -2.5, 15.5, -9.5, east),
--     },
--     rectangles = {
--         {x1 = -16, x2 = 16, y1 = -16, y2 = 16, tile = "factory-wall-1"},
--         {x1 = -15, x2 = 15, y1 = -15, y2 = 15, tile = "factory-floor"},
--     },
-- }

local side_offsets = {
    n = {x = 0,  y = -1,  side_x = 1,  side_y = 0},
    s = {x = 0,  y = 1,   side_x = 1,  side_y = 0},
    e = {x = 1,  y = 0,   side_x = 0,  side_y = 1},
    w = {x = -1, y = 0,   side_x = 0,  side_y = 1}
}

function M.generate_layout(factory_data, quality)
    local layout = {}
    
    -- 1. Базовая информация
    layout.name = factory_data.name
    layout.tier = factory_data.tier or 1
    layout.inside_size = factory_data.inside_size
    layout.outside_size = factory_data.outside_size
    layout.quality = quality
    layout.factory_data = factory_data

    -- 2. Логика Двери
    local door = factory_data.door
    local side = door.side
    local off = side_offsets[side]
    layout.door = door

    layout.outside_door_x = (layout.outside_size / 2) * off.x
    layout.outside_door_y = (layout.outside_size / 2) * off.y
    layout.inside_door_x = (layout.inside_size / 2 + 1) * off.x
    layout.inside_door_y = (layout.inside_size / 2 + 1) * off.y

    -- 3. Энергия (ВОЗВРАЩАЕМ inside_energy_pos)
    -- Расчет позиции столба: 4 тайла вбок от двери и 1 тайл внутрь
    layout.inside_energy_pos = {
        x = layout.inside_door_x + (off.side_x * -4) - (off.x * 1),
        y = layout.inside_door_y + (off.side_y * -4) - (off.y * 1)
    }
    
    layout.outside_energy_receiver_type = factory_data.outside_energy_receiver_type or ("factory-power-input-" .. layout.outside_size)

    -- 4. Оверлеи
    if factory_data.overlays then
        layout.overlays = table.deepcopy(factory_data.overlays)
    else
        layout.overlays = {
            outside_x = 0,
            outside_y = -1,
            outside_w = layout.outside_size,
            outside_h = layout.outside_size - 2,
            inside_pos = { -- Используем таблицу для консистентности
                x = layout.inside_door_x + (off.side_x * -3.5) - (off.x * 2),
                y = layout.inside_door_y + (off.side_y * -3.5) - (off.y * 2)
            }
        }
    end

    -- 5. Cerys (Радиационные башни)
    layout.cerys_radiative_towers = {}
    if factory_data.cerys_radiative_towers then
        for _, pos in ipairs(factory_data.cerys_radiative_towers) do
            -- Вращаем старые координаты (которые обычно для Юга) под текущую дверь
            local rotated = rotate_pos(pos[1], pos[2], side)
            table.insert(layout.cerys_radiative_towers, {x = rotated.x, y = rotated.y})
        end
    else
        -- Дефолт: башни по углам внутри
        local dist = (layout.inside_size / 2) - 5
        layout.cerys_radiative_towers = {
            {x = -dist, y = -dist}, {x = dist, y = -dist},
            {x = -dist, y = dist}, {x = dist, y = dist}
        }
    end

    -- 6. Остальное
    layout.outside_requester_chest = factory_data.outside_requester_chest or ("factory-requester-chest-" .. layout.name)
    layout.outside_ejector_chest = factory_data.outside_ejector_chest or ("factory-eject-chest-" .. layout.name)

    layout.connections = connections.generate_connections(factory_data, quality)
    layout.connection_tile = "factory-connection-tile"
    
    layout.rectangles = factory_data.rectangles or {}
    layout.mosaics = factory_data.mosaics or {}

    return layout
end


return M