local M = {}

if data then
    local colors = require("__FactorissimoLib__/lib/colors")
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    local function wall_mask()
        return { layers = { ground_tile = true, water_tile = true, resource = true, floor = true, item = true, object = true, player = true, doodad = true } }
    end

    local function floor_mask()
        return { layers = { ground_tile = true } }
    end

    function M.createColoredTile(type, color, forced_name)
        color = colors.color_normalize(color)
        local name = forced_name or (type .. "-color-" .. math.floor(color.r * 255) .. "-" .. math.floor(color.g * 255) .. "-" .. math.floor(color.b * 255))
        if data.raw.tile[name] then return data.raw.tile[name] end
        local deepcopy = (util and util.deepcopy) or (table and table.deepcopy)
        if not deepcopy then error("No deepcopy function found") end
        
        local tile = deepcopy(base_prototypes.tile)
        tile.name = name
        tile.tint = color
        tile.map_color = color
        tile.collision_mask = (type == "factory-wall") and wall_mask() or floor_mask()
        data:extend({tile})
        return name
    end

    M.createColoredTile("factory-floor", {r=0.55, g=0.55, b=0.55}, "factory-floor")
    M.createColoredTile("factory-floor", {r=0.55, g=0.55, b=0.55}, "factory-entrance-floor")
    M.createColoredTile("factory-floor", {r=0.55, g=0.55, b=0.55}, "factory-connection-tile")
end

return M