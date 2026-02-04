local M = {}

if data then
    local Auxilary = require("__FactorissimoLib__/lib/factory/auxilary")
    local F = "__FactorissimoLib__"

    -- Создаем базовый айтем настроек
    Auxilary.create_settings_item()

    -- 2. Индикаторы (сгруппируем для удобства)
    local indicators = {
        {type = "belt",    suffix = "d0",   img = "green-dir"},
        {type = "fluid",   suffix = "d0",   img = "blue-dir"},
        {type = "circuit", suffix = "b0",   img = "yellow-dot"},
        -- Сундуки
        {type = "chest",   suffix = "d0",   img = "brown-dir"},
        {type = "chest",   suffix = "d600", img = "brown-dir"},
        {type = "chest",   suffix = "b600", img = "brown-dot"},
        -- Тепло
        {type = "heat",    suffix = "b0",   img = "red-dot"},
        {type = "heat",    suffix = "b120", img = "red-dot"},
    }

    for _, ind in ipairs(indicators) do
        Auxilary.create_indicator(ind.type, ind.suffix, F .. "/graphics/indicator/" .. ind.img .. ".png")
    end

    -- 3. Силовые опоры
    -- Название, имя донора (откуда берем визуал), радиус покрытия
    Auxilary.create_custom_pole("factory-power-pole", "substation", 63)
    Auxilary.create_custom_pole("factory-global-electric-network-pole", "substation", 1)

    -- 4. Специфические объекты (можно добавить в библиотеку или создать здесь)
    data:extend({
        {
            type = "simple-entity-with-force",
            name = "factory-blueprint-anchor",
            flags = {"player-creation", "placeable-off-grid"},
            collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
            selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
            placeable_by = {item = "factory-connection-indicator-settings", count = 1}
        }
    })
    data:extend({
        {
            type = "assembling-machine",
            name = "factory-air-conditioner",
            icon = "__FactorissimoLib__/graphics/icon/regulator.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation", "not-on-map"},
            minable = {mining_time = 0.5, result = "factory-air-conditioner"},
            max_health = 500,

            -- Немного расширяем бокс до 1.4, чтобы трубы на 1.2 смотрелись логично
            collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
            selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
            
            crafting_categories = {"factory-conditioning"},
            fixed_recipe = "factory-air-conditioning-process",
            crafting_speed = 1,
            energy_usage = "250kW",

            energy_source = {
                type = "fluid",
                fluid_box = {
                    production_type = "input",
                    pipe_covers = pipecoverspictures(),
                    pipe_picture = require("__space-age__.prototypes.entity.electromagnetic-plant-pictures").pipe_pictures,
                    volume = 100,
                    pipe_connections = {
                        {position = {0, -1.2}, direction = defines.direction.north},
                    },
                },
                burns_fluid = false,
                scale_fluid_usage = true,
            },
            -- ... (графика и звуки остаются без изменений) ...
            graphics_set = {
                animation = {
                    layers = {
                        {
                            filename = "__FactorissimoLib__/graphics/entity/regulator.png",
                            priority = "high",
                            width = 210, 
                            height = 290,
                            shift = {0, -0.5},
                            frame_count = 60,
                            line_length = 8,
                            animation_speed = 1,
                            scale = 0.5,
                        },
                        {
                            filename = "__FactorissimoLib__/graphics/entity/regulator-shadow.png",
                            priority = "high",
                            width = 400,
                            height = 350,
                            shift = {0.5, 0},
                            frame_count = 1,
                            repeat_count = 60,
                            draw_as_shadow = true,
                            scale = 0.5,
                        }
                    }
                }
            },
        }
    })

    -- 3. Предмет
    data:extend({
        {
            type = "item",
            name = "factory-air-conditioner",
            icon = F .. "/graphics/icon/regulator.png",
            icon_size = 64,
            subgroup = "factorissimo-parts",
            place_result = "factory-air-conditioner",
            stack_size = 10
        }
    })

    -- 4. Рецепт-процесс (чтобы кондиционер "работал")
    data:extend({
        {
            type = "recipe",
            name = "factory-air-conditioning-process",
            enabled = true,
            hidden = true, -- Скрыт из меню крафта игрока
            energy_required = 1,
            ingredients = {}, -- Ингредиенты не нужны, так как мы потребляем fluid через energy_source
            results = {{type = "item", name = "factory-air-conditioner", amount = 0}}, -- Пустой результат
            category = "factory-conditioning"
        }
    })
    data:extend({
        {
            type = "simple-entity-with-force",
            name = "factory-horizontal-exit-door",
            icon = "__FactorissimoLib__/graphics/icon/factory-subicon.png",
            icon_size = 64,
            flags = {
                "placeable-neutral", 
                "player-creation", 
                "not-repairable", 
                "not-on-map", 
                "not-selectable-in-game" -- Добавь, если не хочешь, чтобы её можно было "выбрать" мышкой
            },
            minable = nil,
            max_health = 500,
            -- Ширина 4 (от -1.9 до 1.9), высота 2 (от -0.9 до 0.9)
            -- Оставляем зазор 0.1, чтобы дверь не "застревала" в соседних тайлах
            collision_box = {{-1.9, -0.9}, {1.9, 0.9}}, 
            collision_mask = {layers = {}}, -- Игрок проходит насквозь
            selection_box = {{-2.0, -1.0}, {2.0, 1.0}},
            render_layer = "object",
            picture = {
                filename = "__core__/graphics/empty.png",
                width = 1,
                height = 1,
            }
        }
    })
    data:extend({
        {
            type = "simple-entity-with-force",
            name = "factory-vertical-exit-door",
            icon = "__FactorissimoLib__/graphics/icon/factory-subicon.png",
            icon_size = 64,
            flags = {
                "placeable-neutral", 
                "player-creation", 
                "not-repairable", 
                "not-on-map", 
                "not-selectable-in-game" -- Добавь, если не хочешь, чтобы её можно было "выбрать" мышкой
            },
            minable = nil,
            max_health = 500,
            -- Ширина 4 (от -1.9 до 1.9), высота 2 (от -0.9 до 0.9)
            -- Оставляем зазор 0.1, чтобы дверь не "застревала" в соседних тайлах
            collision_box = {{-0.9, -1.9}, {0.9, 1.9}}, 
            collision_mask = {layers = {}}, -- Игрок проходит насквозь
            selection_box = {{-2.0, -1.0}, {2.0, 1.0}},
            render_layer = "object",
            picture = {
                filename = "__core__/graphics/empty.png",
                width = 1,
                height = 1,
            }
        }
    })
    local factory_radar = table.deepcopy(data.raw["radar"]["radar"])
    factory_radar.name = "factorissimo-factory-radar"
    factory_radar.hidden_in_factoriopedia = true
    factory_radar.hidden = true -- Скрыть из списков выбора

    -- Убираем физическое присутствие и возможность нажать
    factory_radar.flags = {
        "placeable-off-grid", 
        "not-on-map", 
        "not-blueprintable", 
        "not-deconstructable", 
        "not-repairable"
    }
    factory_radar.collision_box = nil
    factory_radar.selection_box = nil
    factory_radar.selectable_in_game = false

    -- Делаем его абсолютно прозрачным (пустая картинка)
    local empty_sprite = {
        filename = "__core__/graphics/empty.png",
        priority = "extra-high",
        width = 1,
        height = 1,
        frame_count = 1,
        direction_count = 1,
    }
    factory_radar.pictures = {
        layers = { empty_sprite }
    }

    factory_radar.energy_source = { type = "void" }
    factory_radar.max_distance_of_sector_revealed = 8
    factory_radar.max_distance_of_nearby_sector_revealed = 8

    data:extend({ factory_radar })

    data:extend {{
        type = "item",
        name = "factory-circuit-connector",
        icon = F .. "/graphics/icon/factory-circuit-connector.png",
        icon_size = 64,
        flags = {},
        subgroup = "factorissimo-parts",
        order = "c-b",
        place_result = "factory-circuit-connector",
        stack_size = 50,
    }}

    data:extend {{
        type = "electric-pole",
        name = "factory-circuit-connector",
        icon = F .. "/graphics/icon/factory-circuit-connector.png",
        icon_size = 64,
        flags = {"placeable-neutral", "player-creation"},
        minable = {mining_time = 0.5, result = "factory-circuit-connector"},
        max_health = 50,
        corpse = "small-remnants",
        supply_area_distance = 0,
        draw_copper_wires = false,
        collision_box = {{-0.35, -0.35}, {0.35, 0.35}},
        selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
        auto_connect_up_to_n_wires = 0,
        pictures = {
            layers = {
                {
                    direction_count = 1,
                    filename = F .. "/graphics/entity/factory-circuit-connector.png",
                    width = 64,
                    height = 64,
                    scale = 0.51,
                },
                {
                    direction_count = 1,
                    filename = F .. "/graphics/entity/factory-circuit-connector-sh.png",
                    width = 85,
                    height = 85,
                    scale = 0.51,
                    draw_as_shadow = true,
                },
            }
        },
        connection_points = {{
            shadow = {
                red = {0.75, 0.5625},
                green = {0.21875, 0.5625}
            },
            wire = {
                red = {0.28125, 0.15625},
                green = {-0.21875, 0.15625}
            }
        }},
        maximum_wire_distance = 14,
    }}

    data:extend {
        -- Utilities
        {
            type = "recipe",
            name = "factory-circuit-connector",
            enabled = false,
            energy_required = 1,
            ingredients = {
                {type = "item", name = "electronic-circuit", amount = 2},
                {type = "item", name = "copper-cable",       amount = 5}
            },
            results = {{type = "item", name = "factory-circuit-connector", amount = 1}},
        }
    }

    -- small vanilla change to allow factories to be crafted at the start of the game
    if data.raw["recipe-category"]["metallurgy-or-assembling"] then
        table.insert(data.raw["assembling-machine"]["assembling-machine-1"].crafting_categories or {}, "metallurgy-or-assembling")
    end
end