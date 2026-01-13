local F = "__FactorissimoLib__"
if false then
    example_factory_1 = {
    type = "factory",
    name = "factory-1",
    tier = 1,
    conditioned = false,
    outside_size = 8,
    inside_size = 30,
    max_health = 4000,
    color = {r = 0.8, g = 0.7, b = 0.55},
    graphics = {
        icon = F .. "/graphics/icon/factory-1.png",
        icon_size = 64,
        pictures = {
            picture = {
                layers = {
                    {
                        filename = F .. "/graphics/factory/factory-1-shadow.png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                        draw_as_shadow = true
                    },
                    {
                        filename = F .. "/graphics/factory/factory-1.png",
                        width = 416 * 2,
                        height = 320 * 2,
                        scale = 0.5,
                        shift = {1.5, 0},
                    }
                }
            },
        },
    },
    recipe = {
        energy_required = 30,
        ingredients = {
            {type = "item", name = "stone",        amount = 500},
            {type = "item", name = "iron-plate",   amount = 500},
            {type = "item", name = "copper-plate", amount = 200}
        },
    },
    recipe_alternatives = {
        {
            recipe = {
                energy_required = 30,
                ingredients = {
                    {type = "item", name = "stone",        amount = 500},
                    {type = "item", name = "iron-plate",   amount = 500},
                    {type = "item", name = "copper-plate", amount = 200}
                },
            },
            condition = "space-age"
        }
    },
    technology = {
        name = "factory-architecture-t1",
        icon = F .. "/graphics/technology/factory-architecture-1.png",
        icon_size = 256,
        prerequisites = {"stone-wall", "logistics"},
        time = 30,
        count = 100,
        ingredients = {{"automation-science-pack", 1}},
    },
    technology_alternatives = {
        {
            technology = {
                name = "factory-architecture-t1",
                icon = F .. "/graphics/technology/factory-architecture-1.png",
                icon_size = 256,
                prerequisites = {"stone-wall", "logistics"},
                time = 30,
                count = 100,
                ingredients = {{"automation-science-pack", 1}},
            },
            condition = "space-age"
        }
    },
    
    pattern = "01",
    connections_per_side = 4,
}
end