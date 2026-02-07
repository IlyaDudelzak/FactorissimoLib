local M = {}

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
    local EntityLib = require("__FactorissimoLib__/lib/factory/entity")
    local Alternatives = require("__FactorissimoLib__/lib/alternatives")

    M.make_entity = function(factory_data)
        return EntityLib.make_building(factory_data)
    end

    M.make_item = function(factory_data)
        local item = table.deepcopy(base_prototypes.item[factory_data.type])
        item.name = factory_data.name
        item.icon = factory_data.graphics.icon
        item.icon_size = factory_data.graphics.icon_size
        item.place_result = factory_data.name
        item.order = "a[" .. factory_data.tier .. "]"
        return item
    end

    M.make_instantiated_item = function(factory_data)
        if factory_data.type == "space-platform-hub" then return nil end
        local item_inst = table.deepcopy(base_prototypes.item_instantiated["factory"])
        item_inst.name = factory_data.name .. "-instantiated"
        item_inst.localised_name = {"item-name.factory-packed", {"entity-name." .. factory_data.name}}
        item_inst.icons = {
            {
                icon = factory_data.graphics.icon,
                icon_size = factory_data.graphics.icon_size,
            },
            {
                icon = F .. "/graphics/icon/packing-tape.png",
                icon_size = 64,
            }
        }
        item_inst.place_result = factory_data.name
        return item_inst
    end

    M.make_recipe = function(factory_data)
        if not factory_data.recipe then return nil end
        local recipe = table.deepcopy(base_prototypes.recipe)
        local item_name = factory_data.name
        recipe.name = item_name
        recipe.ingredients = factory_data.recipe.ingredients
        recipe.results = {{type = "item", name = item_name, amount = 1}}
        recipe.enabled = false
        return recipe
    end

    M.make_technology = function(factory_data)
        if not factory_data.technology then return nil end
        local tech = table.deepcopy(base_prototypes.technology)
        local item_name = factory_data.name
        tech.name = factory_data.technology.name
        tech.icon = factory_data.technology.icon
        tech.icon_size = factory_data.technology.icon_size
        tech.prerequisites = factory_data.technology.prerequisites

        -- Ensure unit property is correctly structured
        tech.unit = {
            count = factory_data.technology.count or 100, -- Default to 100 if not provided
            time = factory_data.technology.time or 30, -- Default to 30 if not provided
            ingredients = factory_data.technology.ingredients or {{"automation-science-pack", 1}} -- Default ingredients
        }

        -- Add effects to unlock the recipe
        tech.effects = {{
            type = "unlock-recipe",
            recipe = item_name
        }}

        return tech
    end
    M.make_requester_chest = function(factory_data)
        local requester_chest = table.deepcopy(data.raw.container["steel-chest"])
        requester_chest.name = "factory-requester-chest-" .. factory_data.name
        requester_chest.localised_name = {"entity-name.factory-requester-chest"}
        requester_chest.icon = factory_data.graphics.icon
        requester_chest.icon_size = factory_data.graphics.icon_size
        
        -- Копируем коллизию из параметров графики или сущности
        requester_chest.collision_box = factory_data.graphics.collision_box or {{-0.5, -0.5}, {0.5, 0.5}}
        requester_chest.selection_box = nil
        requester_chest.inventory_type = "with_custom_stack_size"
        requester_chest.inventory_properties = {stack_size_multiplier = 50}
        requester_chest.inventory_size = 100
        requester_chest.picture = {
            filename = "__core__/graphics/empty.png",
            width = 1, height = 1, frame_count = 1
        }
        requester_chest.hidden = true
        requester_chest.factoriopedia_alternative = factory_data.name
        requester_chest.flags = {"not-on-map", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion", "not-in-kill-statistics", "not-rotatable", "placeable-off-grid"}
        
        -- Общие правки (коллизии и маски)
        requester_chest.collision_mask = {layers = {}}
        requester_chest.subgroup = "factorissimo-roboports"
        requester_chest.max_health = 500
        
        return requester_chest
    end

    M.make_eject_chest = function(factory_data)
        local eject_chest = table.deepcopy(data.raw.container["steel-chest"])
        eject_chest.name = "factory-eject-chest-" .. factory_data.name
        eject_chest.inventory_size = 1
        eject_chest.localised_name = {"entity-name.factory-eject-chest"}
        eject_chest.icon = factory_data.graphics.icon
        eject_chest.icon_size = factory_data.graphics.icon_size
        eject_chest.collision_box = factory_data.graphics.collision_box or {{-0.5, -0.5}, {0.5, 0.5}}
        eject_chest.selection_box = nil
        eject_chest.picture = {
            filename = "__core__/graphics/empty.png",
            width = 1, height = 1, frame_count = 1
        }
        eject_chest.hidden = true
        eject_chest.factoriopedia_alternative = factory_data.name
        eject_chest.flags = {"not-on-map", "hide-alt-info", "no-automated-item-removal", "no-automated-item-insertion", "not-in-kill-statistics", "not-rotatable", "placeable-off-grid"}
        
        e_mask = {layers = {}}
        eject_chest.collision_mask = {layers = {}}
        eject_chest.subgroup = "factorissimo-roboports"
        eject_chest.max_health = 500
        
        return eject_chest
    end
end

return M