local M = {}

-- Вспомогательная функция для пустых соединений проводов
local function cwc0c()
    return {shadow = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}, wire = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}}
end

-- 1. Интерфейсы энергии (зависят от размера фабрики)
M.create_energy_interface = function(factory_data)
    local size = factory_data.outside_size
    local j = size / 2 - 0.3
    
    return {
        type = "electric-energy-interface",
        name = "factory-power-input-" .. size,
        icon = factory_data.graphics.icon,
        icon_size = factory_data.graphics.icon_size,
        flags = {"not-on-map"},
        selection_priority = 1,
        max_health = 1,
        hidden = true,
        selectable_in_game = false,
        energy_source = {
            type = "electric",
            usage_priority = "tertiary",
            input_flow_limit = "0W",
            output_flow_limit = "0W",
            buffer_capacity = "0J",
            render_no_power_icon = false,
        },
        energy_usage = "0MW",
        energy_production = "0MW",
        selection_box = {{-j, -j}, {j, j}},
        collision_box = {{-j, -j}, {j, j}},
        collision_mask = {layers = {}},
        localised_name = "",
    }
end

-- 2. Индикаторы соединений (конвейеры, сундуки и т.д.)
M.create_indicator = function(ctype, suffix, image, asset_path)
    return {
        type = "storage-tank",
        name = "factory-connection-indicator-" .. ctype .. "-" .. suffix,
        localised_name = {"entity-name.factory-connection-indicator-" .. ctype},
        flags = {"not-on-map", "player-creation", "not-deconstructable"},
        placeable_by = {item = "factory-connection-indicator-settings", count = 1},
        max_health = 500,
        selection_box = {{-0.4, -0.4}, {0.4, 0.4}},
        collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
        collision_mask = {not_colliding_with_itself = true, layers = {}},
        fluid_box = { volume = 1, pipe_connections = {} },
        hidden = true,
        window_bounding_box = {{0, 0}, {0, 0}},
        selection_priority = 52,
        pictures = {
            picture = {
                sheet = {
                    filename = asset_path .. "/graphics/indicator/" .. image .. ".png",
                    priority = "extra-high",
                    frames = 4,
                    width = 64,
                    height = 64,
                    scale = 0.5
                },
            },
        },
        flow_length_in_ticks = 100,
        circuit_wire_max_distance = 0
    }
end

-- 3. Статические сущности (которые не меняются от типа фабрики)
M.get_static_auxiliaries = function()
    local j_pole = 0.99
    return {
        -- Якорь чертежа
        {
            type = "simple-entity-with-force",
            name = "factory-blueprint-anchor",
            flags = {"player-creation", "placeable-off-grid"},
            hidden = true,
            collision_box = {{-0.5, -0.5}, {0.5, 0.5}},
            selection_box = {{-0.5, -0.5}, {0.5, 0.5}},
            placeable_by = {item = "simple-entity-with-force", count = 1}
        },
        -- Скрытый столб питания
        {
            type = "electric-pole",
            name = "factory-power-pole",
            max_health = 500,
            selection_box = {{-j_pole, -j_pole}, {j_pole, j_pole}},
            collision_box = {{-j_pole, -j_pole}, {j_pole, j_pole}},
            collision_mask = {layers = {}},
            icon = data.raw.item["substation"].icon,
            icon_size = data.raw.item["substation"].icon_size,
            flags = {"not-on-map"},
            auto_connect_up_to_n_wires = 0,
            hidden = true,
            maximum_wire_distance = 1,
            supply_area_distance = 63,
            pictures = table.deepcopy(data.raw["electric-pole"]["substation"].pictures),
            connection_points = {cwc0c(), cwc0c(), cwc0c(), cwc0c()},
        }
        -- И так далее для радара, оверлей-контроллера и прочего...
    }
end

return M