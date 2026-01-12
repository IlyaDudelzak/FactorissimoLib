local alternatives = require("lib.alternatives")
local M = {}
_G.tiles = _G.tiles or {}

local function wall_mask()
    return { layers = { ground_tile = true, water_tile = true, resource = true, floor = true, item = true, object = true, player = true, doodad = true } }
end

local function floor_mask()
    return { layers = { ground_tile = true } }
end

function M.createColoredTile(type, color)
    color = factorissimo.color_normalize(color)
    local name = type .. "-color-" .. math.floor(color.r * 255) .. "-" .. math.floor(color.g * 255) .. "-" .. math.floor(color.b * 255)
    if tiles[name] then return tiles[name] end
    
    -- Используем deepcopy из util, если доступен, иначе выдаём ошибку
    local deepcopy = (util and util.deepcopy) or (table and table.deepcopy)
    if not deepcopy then error("No deepcopy function found (util.deepcopy or table.deepcopy required)") end
    local tile = deepcopy(data.raw.tile["lab-dark-1"] or data.raw.tile["stone-path"])
    tile.name = name
    tile.tint = color
    tile.map_color = color
    tile.collision_mask = (type == "factory-wall") and wall_mask() or floor_mask()
    -- Применяем альтернативы (патчи/оверрайды) для тайлов
    tile = alternatives.apply_alternatives("tile", tile)
    tiles[name] = tile
    return tile
end

function M.addToData()
    local to_extend = {}
    for _, tile in pairs(tiles) do table.insert(to_extend, tile) end
    data:extend(to_extend)
end

return M