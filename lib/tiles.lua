local colors = require("__FactorissimoLib__/lib/colors")
local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

local M = {}
M.tiles = M.tiles or {}
----------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------

local function wall_mask()
    return { layers = { ground_tile = true, water_tile = true, resource = true, floor = true, item = true, object = true, player = true, doodad = true } }
end

local function floor_mask()
    return { layers = { ground_tile = true } }
end

----------------------------------------------------------------
-- ОСНОВНАЯ ЛОГИКА
----------------------------------------------------------------

function M.createColoredTile(type, color)
    -- 1. Нормализуем цвет и генерируем уникальное имя
    color = colors.color_normalize(color)
    local name = type .. "-color-" .. math.floor(color.r * 255) .. "-" .. math.floor(color.g * 255) .. "-" .. math.floor(color.b * 255)
    
    -- 2. Если тайл уже есть в локальной памяти текущего файла — возвращаем его
    if M.tiles[name] then return M.tiles[name] end

    -- 3. Подготовка структуры тайла (Deepcopy)
    local deepcopy = (util and util.deepcopy) or (table and table.deepcopy)
    if not deepcopy then error("No deepcopy function found") end
    
    local tile = deepcopy(base_prototypes.tile)
    tile.name = name
    tile.tint = color
    tile.map_color = color
    tile.collision_mask = (type == "factory-wall") and wall_mask() or floor_mask()
    data:extend({tile})
    
end

-- Инициализация базового пола (тоже пойдет в банк)
M.createColoredTile("factory-floor", {r=0.55, g=0.55, b=0.55})

return M