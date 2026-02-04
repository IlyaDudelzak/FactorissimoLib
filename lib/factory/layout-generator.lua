local M = {}

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
    
    local i = #tiles
    
    -- Итерируемся строго по размеру массива паттерна
    for y = 1, h do
        local line = pattern[y]
        for x = 1, w do
            -- Проверяем символ
            if string.sub(line, x, x) == "+" then
                i = i + 1
                -- Мировые координаты = индекс в массиве + оффсет
                -- (x-1), потому что индексы Lua начинаются с 1, а координаты с 0
                tiles[i] = {
                    name = tile_name, 
                    position = {x - 1 + x_offset, y - 1 + y_offset}
                }
            end
        end
    end
end

local function max_connections_count(factory_data)
    local max_inside = (math.floor((factory_data.inside_size / 2 - 1) / 2)) * 2
    local max_outside = (math.floor((factory_data.outside_size - 1) / 2)) * 2
    return math.min(max_inside, max_outside)
end



function M.add_walls(factory_data, tiles)
    local size = factory_data.inside_size
    -- extent — это радиус пола. Для размера 16, extent = 8 (пол от -8 до 7).
    local extent = size / 2
    
    -- Динамическое имя плитки стены на основе цвета
    local tile_name = "factory-wall-color-" .. 
        math.floor(factory_data.color.r * 255) .. "-" .. 
        math.floor(factory_data.color.g * 255) .. "-" .. 
        math.floor(factory_data.color.b * 255)
    
    local i = #tiles

    -- 1. Горизонтальные линии (Верх и Низ)
    -- Проходим от -8-1 (-9) до 8. Итого 18 плиток в ширину.
    for x = -extent - 1, extent do
        -- Верхняя граница (Y = -9)
        i = i + 1
        tiles[i] = {name = tile_name, position = {x, -extent - 1}}
        
        -- Нижняя граница (Y = 8)
        i = i + 1
        tiles[i] = {name = tile_name, position = {x, extent}}
    end

    -- 2. Вертикальные линии (Лево и Право)
    -- Углы уже заняты горизонтальными линиями, поэтому идем от -8 до 7.
    for y = -extent, extent - 1 do
        -- Левая граница (X = -9)
        i = i + 1
        tiles[i] = {name = tile_name, position = {-extent - 1, y}}
        
        -- Правая граница (X = 8)
        i = i + 1
        tiles[i] = {name = tile_name, position = {extent, y}}
    end
end

function M.make_tiles(factory_data)
    local tiles = {}
    M.add_tile_mosaic(factory_data, tiles)
    M.add_walls(factory_data, tiles)
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

function M.generate_layout(factory_data, quality)
    local pattern = pattern_gen.generate(factory_data.pattern)
    local layout = {}
    layout.connections = M.make_connections(factory_data, quality)  
    layout.tiles = M.make_tiles(factory_data)
    layout.quality = quality
    return layout
end


return M