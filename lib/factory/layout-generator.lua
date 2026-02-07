local M = {}

local connections = require("lib.factory.connections")

local pattern_gen = require("lib.pattern-gen")

M.SIDE_PRIORITY = { s = 1, n = 2, e = 3, w = 4 }

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

function factorissimo.rotate_pos(a, b, c)
    local x = 0
    local y = 0
    local side = "n"

    if c then 
        x = a
        y = b
        side = c
    else
        x = a.x
        y = a.y
        side = b
    end
    
    if side == "s" then return {x = x, y = y} end
    if side == "n" then return {x = -x - 1, y = -y - 1} end
    if side == "e" then return {x = y, y = -x - 1} end
    if side == "w" then return {x = -y - 1, y = x} end
    return {x = x, y = y}
end

function M.add_entrance(factory_data, tiles)
    if not factory_data.door or not factory_data.door.side then return end
    
    local sides = type(factory_data.door.side) == "table" and factory_data.door.side or {factory_data.door.side}
    local extent = factory_data.inside_size / 2
    local wall_tile = "factory-wall-color-" .. math.floor(factory_data.color.r * 255) .. "-" .. math.floor(factory_data.color.g * 255) .. "-" .. math.floor(factory_data.color.b * 255)
    local entrance_tile = "factory-entrance-floor"

    for _, side in ipairs(sides) do
        local i = #tiles
        for dy = 0, 3 do
            for dx = -2, 1 do
                local p = factorissimo.rotate_pos(dx, extent + dy, side)
                tiles[#tiles + 1] = {name = entrance_tile, position = {p.x, p.y}}
            end
        end

        for dy = 1, 3 do
            local p1 = factorissimo.rotate_pos(-3, extent + dy, side)
            local p2 = factorissimo.rotate_pos(2, extent + dy, side)
            tiles[#tiles + 1] = {name = wall_tile, position = {p1.x, p1.y}}
            tiles[#tiles + 1] = {name = wall_tile, position = {p2.x, p2.y}}
        end

        local wall_offsets = {-5, -4, -3, 2, 3, 4}
        for _, dx in ipairs(wall_offsets) do
            local p = factorissimo.rotate_pos(dx, extent, side)
            tiles[#tiles + 1] = {name = wall_tile, position = {p.x, p.y}}
        end
    end
end

function M.add_walls(factory_data, tiles)
    local size = factory_data.inside_size
    local extent = size / 2
    local tile_name = "factory-wall-color-" .. math.floor(factory_data.color.r * 255) .. "-" .. math.floor(factory_data.color.g * 255) .. "-" .. math.floor(factory_data.color.b * 255)
    
    local sides = type(factory_data.door.side) == "table" and factory_data.door.side or {factory_data.door.side}
    local is_door = {}
    for _, s in ipairs(sides) do is_door[s] = true end

    -- Горизонтальные стены
    for x = -extent - 1, extent do
        if not (is_door["n"] and x >= -5 and x <= 4) then
            tiles[#tiles + 1] = {name = tile_name, position = {x, -extent - 1}}
        end
        if not (is_door["s"] and x >= -5 and x <= 4) then
            tiles[#tiles + 1] = {name = tile_name, position = {x, extent}}
        end
    end

    -- Вертикальные стены
    for y = -extent, extent - 1 do
        if not (is_door["w"] and y >= -5 and y <= 4) then
            tiles[#tiles + 1] = {name = tile_name, position = {-extent - 1, y}}
        end
        if not (is_door["e"] and y >= -5 and y <= 4) then
            tiles[#tiles + 1] = {name = tile_name, position = {extent, y}}
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
    layout.name = factory_data.name
    layout.inside_size = factory_data.inside_size
    layout.outside_size = factory_data.outside_size
    layout.factory_data = factory_data

    -- 1. Обработка списка сторон
    local sides = type(factory_data.door.side) == "table" and factory_data.door.side or {factory_data.door.side}
    
    -- Выбираем главную сторону (для подстанции и оверлея)
    local main_side = sides[1]
    for i = 2, #sides do
        if M.SIDE_PRIORITY[sides[i]] < M.SIDE_PRIORITY[main_side] then main_side = sides[i] end
    end
    
    layout.main_side = main_side
    layout.all_sides = sides
    
    -- !!! ВОТ ЭТОГО НЕ ХВАТАЛО !!!
    -- Мы сохраняем структуру door, чтобы create_factory_doors видела размер и стороны
    layout.door = {
        side = sides,
        size = factory_data.door.size
    }
    
    local off = side_offsets[main_side]
    layout.inside_door_x = (layout.inside_size / 2 + 1) * off.x
    layout.inside_door_y = (layout.inside_size / 2 + 1) * off.y

    -- Координаты для exterior (чтобы не было nil в арифметике)
    layout.outside_door_x = (layout.outside_size / 2) * off.x
    layout.outside_door_y = (layout.outside_size / 2) * off.y

    -- 2. Энергия
    layout.inside_energy_pos = {
        x = layout.inside_door_x + (off.side_x * -4) - (off.x * 1),
        y = layout.inside_door_y + (off.side_y * -4) - (off.y * 1) + 2
    }
    
    layout.outside_energy_receiver_type = factory_data.outside_energy_receiver_type or ("factory-power-input-" .. layout.outside_size)

    -- 3. Оверлеи
    if factory_data.overlays then
        layout.overlays = table.deepcopy(factory_data.overlays)
    else
        layout.overlays = {
            outside_x = 0,
            outside_y = (main_side == "n" or main_side == "s") and (layout.outside_door_y - off.y) or 0,
            outside_w = layout.outside_size,
            outside_h = layout.outside_size - 2,
            inside_pos = {
                x = layout.inside_door_x + (off.side_x * -3.5) - (off.x * 2),
                y = layout.inside_door_y + (off.side_y * -3.5) - (off.y * 2)
            }
        }
    end

    -- 4. Cerys (Исправил side на main_side)
    layout.cerys_radiative_towers = {}
    if factory_data.cerys_radiative_towers then
        for _, pos in ipairs(factory_data.cerys_radiative_towers) do
            local rotated = factorissimo.rotate_pos(pos[1], pos[2], main_side)
            table.insert(layout.cerys_radiative_towers, {x = rotated.x, y = rotated.y})
        end
    else
        local dist = (layout.inside_size / 2) - 5
        layout.cerys_radiative_towers = {
            {x = -dist, y = -dist}, {x = dist, y = -dist},
            {x = -dist, y = dist}, {x = dist, y = dist}
        }
    end

    -- 5. Остальное
    layout.outside_requester_chest = factory_data.outside_requester_chest or ("factory-requester-chest-" .. layout.name)
    layout.outside_ejector_chest = factory_data.outside_ejector_chest or ("factory-eject-chest-" .. layout.name)

    layout.connections = connections.generate_connections(factory_data, quality)
    layout.connection_tile = "factory-connection-tile"
    
    layout.rectangles = factory_data.rectangles or {}
    layout.mosaics = factory_data.mosaics or {}

    return layout
end


return M