local F = "__FactorissimoLib__"

if not data.raw["surface-property"]["ceiling"] then
    data:extend({
        {
            type = "surface-property",
            name = "ceiling",
            default_value = 0,
            is_time_variable = false
        }
    })
end

data:extend {{
    type = "planet",
    name = "factory-travel-surface",
    localised_name = "mod-logic.travel-surface-name",
    hidden = true,
    icon = "__base__/graphics/icons/space-science-pack.png",
    icon_size = 64,
    gravity_pull = 0,
    distance = 0,
    orientation = 0,
    map_gen_settings = {
        height = 1,
        width = 1,
        property_expression_names = {},
        autoplace_settings = {
            ["decorative"] = {treat_missing_as_default = false, settings = {}},
            ["entity"] = {treat_missing_as_default = false, settings = {}},
            ["tile"] = {treat_missing_as_default = false, settings = {}},
        }
    },
    surface_properties = {
        gravity = 0,
        pressure = 1000, -- Стандартное давление
        ["solar-power"] = 0,
    }
}}

-- 2. Вспомогательные функции
local function generate_factory_floor_planet_icons(planet)
    local icons = {}
    
    -- Если у планеты есть слои иконок, копируем их
    if planet.icons then
        icons = table.deepcopy(planet.icons)
    elseif planet.icon then
        table.insert(icons, {icon = planet.icon, icon_size = planet.icon_size or 64})
    end

    -- Сдвигаем и уменьшаем оригинальные иконки планеты в угол
    for _, icon in pairs(icons) do
        icon.scale = (icon.scale or (64 / (icon.icon_size or 64))) * 0.7
        icon.shift = {-8, -8}
    end

    -- Накладываем иконку фабрики поверх (sub-icon)
    table.insert(icons, {
        icon = F .. "/graphics/icon/factory-subicon.png", -- Убедись, что файл существует
        icon_size = 64,
        scale = 0.5,
        shift = {8, 8}
    })

    return icons
end

local function fog_color(planet_name)
    local colors = {
        ["nauvis"]  = {{0.3, 0.3, 0.3}, {0.3, 0.3, 0.3}},
        ["gleba"]   = {{1.0, 1.0, 0.3}, {1.0, 0.0, 1.0}},
        ["vulcanus"]= {{1.0, 0.87, 0.3}, {1.0, 0.87, 0.29}},
        ["fulgora"] = {{0.0, 0.0, 0.6}, {0.6, 0.1, 0.6}},
        ["aquilo"]  = {{0.9, 0.9, 0.9}, {0.6, 0.6, 1.0}}
    }
    local res = colors[planet_name] or {{0.3, 0.3, 0.3}, {0.3, 0.3, 0.3}}
    return res[1], res[2]
end

local function update_render_params(planet, factory_floor)
    local color1, color2 = fog_color(planet.name)
    
    factory_floor.surface_render_parameters = {
        fog = {
            shape_noise_texture = { filename = "__core__/graphics/clouds-noise.png", size = 2048 },
            detail_noise_texture = { filename = "__core__/graphics/clouds-detail-noise.png", size = 2048 },
            color1 = color1,
            color2 = color2,
            fog_type = "vulcanus",
        },
        draw_sprite_clouds = false,
        clouds = nil
    }

    if planet.name == "gleba" then
        factory_floor.player_effects = nil -- Отключаем дождь внутри
    end
end

-- 3. Генерация "этажей" на основе существующих планет
local factory_floors = {}
for _, planet in pairs(data.raw.planet) do
    -- Пропускаем уже созданные этажи и системные поверхности
    if planet.name:match("%-factory%-floor$") then goto continue end

    local factory_floor = table.deepcopy(planet)
    local orig_name = planet.name
    
    factory_floor.name = orig_name .. "-factory-floor"
    factory_floor.localised_name = {"", {"space-location-name." .. orig_name}, {"mod-logic.space"}, {"mod-logic.factory-floor-suffix"}}
    
    -- Убираем космические опасности
    factory_floor.lightning_properties = nil
    factory_floor.asteroid_spawn_definitions = nil
    factory_floor.pollutant_type = nil -- Внутри фабрик своя атмосфера
    
    -- Настройки орбиты и видимости
    factory_floor.distance = planet.distance + 0.1
    factory_floor.draw_orbit = false
    factory_floor.hidden = orig_name == "nauvis" and false or true -- Игрок не может прилететь сюда на корабле
    factory_floor.hidden_in_factoriopedia = true
    
    -- Свойства поверхности (важно для модов)
    factory_floor.surface_properties = factory_floor.surface_properties or {}
    factory_floor.surface_properties["solar-power"] = 0
    factory_floor.surface_properties["day-night-cycle"] = 0
    factory_floor.surface_properties["ceiling"] = 1
    
    -- Иконки
    factory_floor.icons = generate_factory_floor_planet_icons(planet)
    
    update_render_params(planet, factory_floor)

factory_floor.map_gen_settings = {
        terrain_segmentation = 1,
        water = 0,
        autoplace_controls = {},
        autoplace_settings = {
            ["decorative"] = {treat_missing_as_default = false, settings = {}},
            ["entity"] = {treat_missing_as_default = false, settings = {}},
            -- Мы просто говорим игре НЕ использовать стандартные настройки (false),
            -- но не перечисляем тайл out-of-map здесь.
            ["tile"] = {treat_missing_as_default = false, settings = {}}
        },
        property_expression_names = {
            -- elevation ниже 0 при отсутствии других настроек заполнит мир пустотой
            elevation = "-10", 
            moisture = "0",
            temperature = "15"
        }
    }

    table.insert(factory_floors, factory_floor)

    ::continue::
end
data:extend(factory_floors)

for _, tech in pairs(data.raw.technology) do
    if tech.effects then
        local new_effects = {}
        for _, effect in pairs(tech.effects) do
            table.insert(new_effects, effect)
            
            if effect.type == "unlock-space-location" then
                local floor_name = effect.space_location .. "-factory-floor"
                if data.raw.planet[floor_name] then
                    table.insert(new_effects, {
                        type = "unlock-space-location",
                        space_location = floor_name,
                        use_icon_overlay_constant = false,
                    })
                end
            end
        end
        tech.effects = new_effects
    end
end