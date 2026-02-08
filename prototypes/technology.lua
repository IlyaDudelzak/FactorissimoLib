local pf = "p-q-"

local starting_planet = "nauvis"
if mods["any-planet-start"] then
    starting_planet = settings.startup["aps-planet"].value
    if starting_planet == "none" then starting_planet = "nauvis" end
elseif mods["pystellarexpedition"] then
    starting_planet = "frans-orbit"
end

local effects = {
    {
        type = "unlock-recipe",
        recipe = "factory-1"
    }
}

if not mods["solarsystemplusplus"] then
    effects[#effects + 1] = {
        type = "unlock-space-location",
        space_location = starting_planet .. "-factory-floor",
        use_icon_overlay_constant = false,
    }
end

data:extend {
    {
        type = "technology",
        name = "factory-connection-type-fluid",
        icon = F .. "/graphics/technology/factory-connection-type-fluid.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t1"},
        effects = {},
        unit = {
            count = 100,
            ingredients = {{"automation-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-a",
    },
    {
        type = "technology",
        name = "factory-connection-type-chest",
        icon = F .. "/graphics/technology/factory-connection-type-chest.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "logistics-2"},
        effects = {},
        unit = {
            count = 200,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-b",
    },
    {
        type = "technology",
        name = "factory-connection-type-circuit",
        icon = F .. "/graphics/technology/factory-connection-type-circuit.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "circuit-network", "logistic-science-pack"},
        effects = {{type = "unlock-recipe", recipe = "factory-circuit-connector"}},
        unit = {
            count = 300,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "c-c",
    },
    {
        type = "technology",
        name = "factory-connection-type-heat",
        icon = F .. "/graphics/technology/factory-connection-type-heat.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2"},
        effects = {},
        unit = {
            count = 600,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 45
        },
        order = pf .. "c-d",
    },
    {
        type = "technology",
        name = "factory-interior-upgrade-lights",
        icon = F .. "/graphics/technology/factory-interior-upgrade-lights.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t1", "lamp"},
        effects = {},
        unit = {
            count = 50,
            ingredients = {{"automation-science-pack", 1}},
            time = 30
        },
        order = pf .. "d-a",
    },
    {
        type = "technology",
        name = "factory-interior-upgrade-display",
        icon = F .. "/graphics/technology/factory-interior-upgrade-display.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "lamp"},
        effects = {},
        unit = {
            count = 100,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 30
        },
        order = pf .. "d-b",
    },
    {
        type = "technology",
        name = "factory-interior-upgrade-roboport",
        icon = F .. "/graphics/technology/factory-interior-upgrade-roboport.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "construction-robotics"},
        effects = {},
        unit = {
            count = 1000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}},
            time = 45
        },
        order = pf .. "d-d",
    },
    {
        type = "technology",
        name = "factory-recursion-t1",
        icon = F .. "/graphics/technology/factory-recursion-1.png",
        icon_size = 256,
        prerequisites = {"factory-architecture-t2", "logistics-2"},
        effects = {},
        unit = {
            count = 2000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}},
            time = 60
        },
        order = pf .. "b-a",
    },
    {
        type = "technology",
        name = "factory-recursion-t2",
        icon = F .. "/graphics/technology/factory-recursion-2.png",
        icon_size = 256,
        prerequisites = {"factory-recursion-t1", "factory-architecture-t3"},
        effects = {},
        unit = {
            count = 5000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"production-science-pack", 1}},
            time = 60
        },
        order = pf .. "b-b",
    },
}

if mods["space-age"] then 
    data:extend {{
        type = "technology",
        name = "factory-conditioning",
        icon = F .. "/graphics/technology/regulator.png",
        icon_size = 256,
        prerequisites = {"factory-recursion-t1", "factory-architecture-t3"},
        effects = {},
        unit = {
            count = 10000,
            ingredients = {{"automation-science-pack", 1}, {"logistic-science-pack", 1}, {"chemical-science-pack", 1}, {"production-science-pack", 1}, {"utility-science-pack", 1}, {"space-science-pack", 1}},
            time = 60
        },
        order = pf .. "b-c",
    }}
end
