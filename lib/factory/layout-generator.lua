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

function M.add_walls(factory_data, tiles)
    
end

function M.make_tiles(factory_data)
    local tiles = {}
    M.add_tile_mosaic(factory_data, tiles)
    return tiles
end

function M.generate_layout(factory_data)
    local pattern = pattern_gen.generate(factory_data.pattern)
    local pattern_size = #pattern[1]
    if(pattern_size > factory_data.inside_size) then
        error("Pattern size " + pattern_size + " is bigger than inside size " + factory_data.inside_size + " in factory " + factory_data.name)
    end
    return {
        pattern = pattern,
    }
end

if data then
    
else
end

return M