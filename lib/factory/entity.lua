local base_prototypes = require("__factorissimo-3-space-factory__/lib/base-prototypes")

local M = {}

local function make_box(size, offset)
    local r = size / 2 - offset
    return {{-r, -r}, {r, r}}
end

M.make_building = function(factory_data)
    local name = factory_data.name
    local prototype = table.deepcopy(base_prototypes.entity[factory_data.type])
    
    prototype.name = name
    prototype.icon = factory_data.graphics.icon
    prototype.icon_size = factory_data.graphics.icon_size
    prototype.map_color = factory_data.color
    prototype.collision_box = make_box(factory_data.outside_size, 0.2)
    prototype.selection_box = make_box(factory_data.outside_size, 0.2)
    prototype.max_health = factory_data.max_health or (math.pow(2.5, factory_data.tier) * 2000)
    
    if factory_data.type == "factory" then
        prototype.minable.result = name .. "-instantiated"
        prototype.placeable_by.item = name
        prototype.pictures = factory_data.graphics.pictures
    elseif factory_data.type == "space-platform-hub" then
        prototype.weight = 1000 * factory_data.outside_size * factory_data.outside_size
    end
    
    return prototype
end

return M