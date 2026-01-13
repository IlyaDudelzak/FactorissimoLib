local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

local M = {}

M.make_technology = function(factory_data)
    local suffix = factory_data.type == "space-platform-hub" and "-starter-pack" or ""
    local tech = table.deepcopy(base_prototypes.technology)
    local t_data = factory_data.technology
    
    tech.name = t_data.name
    tech.icon = t_data.icon
    tech.icon_size = t_data.icon_size
    tech.prerequisites = t_data.prerequisites
    tech.unit.count = t_data.count
    tech.unit.time = t_data.time
    tech.unit.ingredients = t_data.ingredients
    
    tech.effects = {
        {
            type = "unlock-recipe", 
            recipe = factory_data.name .. suffix
        }
    }
    
    return tech
end

return M