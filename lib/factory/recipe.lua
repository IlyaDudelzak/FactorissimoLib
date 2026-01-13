local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

local M = {}

M.make_recipe = function(factory_data)
    local suffix = factory_data.type == "space-platform-hub" and "-starter-pack" or ""
    local name = factory_data.name .. suffix
    local recipe = table.deepcopy(base_prototypes.recipe)
    
    recipe.name = name
    recipe.ingredients = factory_data.recipe.ingredients
    recipe.results = {{type = "item", name = name, amount = 1}}
    recipe.main_product = name
    recipe.energy_required = factory_data.recipe.energy_required or 30
    
    return recipe
end

return M