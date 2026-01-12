local base_prototypes = require("__factorissimo-3-space-factory__/lib/base-prototypes")

local M = {}

local function get_suffix(factory_data)
    return factory_data.type == "space-platform-hub" and "-starter-pack" or ""
end

M.make_item = function(factory_data)
    local name = factory_data.name .. get_suffix(factory_data)
    local item = table.deepcopy(base_prototypes.item[factory_data.type])
    
    item.name = name
    item.icon = factory_data.graphics.icon
    item.icon_size = factory_data.graphics.icon_size
    item.place_result = factory_data.name
    item.order = "a[" .. factory_data.tier .. "]"
    item.subgroup = factory_data.subgroup or "factorissimo-factories-tier-" .. factory_data.tier
    
    return item
end

M.make_item_instantiated = function(factory_data)
    local name = factory_data.name
    local item = table.deepcopy(base_prototypes.item_instantiated["factory"])
    
    item.name = name .. "-instantiated"
    item.localised_name = {"item-name.factory-packed", {"entity-name." .. name}}
    item.icons[1].icon = factory_data.graphics.icon
    item.icons[1].icon_size = factory_data.graphics.icon_size
    item.place_result = name
    item.factoriopedia_alternative = name
    item.order = "a[" .. factory_data.tier .. "]"
    item.subgroup = factory_data.subgroup or "factorissimo-factories-tier-" .. factory_data.tier
    
    return item
end

return M