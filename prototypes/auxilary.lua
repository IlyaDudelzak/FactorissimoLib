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
            name = "factory-entrance-door",
            icon = "__FactorissimoLib__/graphics/icon/factory-subicon.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation", "not-repairable", "not-on-map"},
            minable = nil,
            max_health = 500,
            -- Ширина 3 (от -1.4 до 1.4), высота 1 (от -0.4 до 0.4)
            collision_box = {{-1.4, -0.4}, {1.4, 0.4}}, 
            collision_mask = {layers = {}}, -- Чтобы игрок проходил насквозь
            selection_box = {{-1.5, -0.5}, {1.5, 0.5}},
            render_layer = "object",
            picture = {
                filename = "__core__/graphics/empty.png",
                width = 1,
                height = 1,
            }
        }
    })
end