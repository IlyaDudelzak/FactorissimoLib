local F = "__FactorissimoLib__"

local tile_trigger_effects = require("__base__.prototypes.tile.tile-trigger-effects")
local sounds = require("__base__.prototypes.entity.sounds")
local item_sounds = require("__base__.prototypes.item_sounds")

local concrete_vehicle_friction_modifier = data.raw["tile"]["concrete"].vehicle_friction_modifier
local concrete_driving_sound = table.deepcopy(data.raw["tile"]["concrete"].driving_sound)
local concrete_tile_build_sounds = table.deepcopy(data.raw["tile"]["concrete"].build_sound)

local utils = require("__FactorissimoLib__/lib/prototype-utils")

local base_prototypes = {
    entity = {
        ["factory"] = {
            type = "storage-tank",
            name = nil,
            icon = nil,
            icon_size = nil,
            flags = {"player-creation", "placeable-player"},
            minable = {mining_time = 0.5, result = "nil-instantiated", count = 1},
            placeable_by = {item = nil, count = 1},
            max_health = nil,
            collision_box = nil,
            selection_box = nil,
            pictures = nil,
            window_bounding_box = {{0, 0}, {0, 0}},
            fluid_box = {
                volume = 1,
                pipe_covers = pipecoverspictures(),
                pipe_connections = {},
            },
            flow_length_in_ticks = 1,
            circuit_wire_max_distance = 0,
            map_color = nil,
            is_military_target = false
        },
        ["space-platform-hub"] = {
            type = "space-platform-hub",
            name = "space-platform-hub-building-tier-1",
            icon = "__space-age__/graphics/icons/space-platform-hub.png",
            icon_size = 64,
            flags = {"player-creation", "not-deconstructable"},
            subgroup = "space-platform",
            order = "b[space-platform-hub]",
            collision_box = nil, 
            selection_box = nil, 
            max_health = nil,
            weight = nil,
            inventory_size = nil,
            dump_container = "crash-site-chest-1",
            circuit_wire_max_distance = default_circuit_wire_max_distance,
            circuit_connector = circuit_connector_definitions["space-platform-hub"],
            default_speed_signal = {type = "virtual", name = "signal-V"},
            default_damage_taken_signal = {type = "virtual", name = "signal-D"},
            platform_repair_speed_modifier = 1,
            open_sound = sounds.metal_large_open,
            close_sound = sounds.metal_large_close,
            surface_conditions = {
                {
                    property = "pressure",
                    min = 0,
                    max = 0
                }
            },
            graphics_set = {
                connections = require("__space-age__.graphics.entity.cargo-hubs.connections.platform-connections"),
                picture = {
                    {
                        render_layer = "lower-object-above-shadow",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-0-A", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-0-B", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-0-C", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-0-D", {scale = 0.5, shift = {0, -1}})
                        }
                    },
                    {
                        render_layer = "lower-object-overlay",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-1-A", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-1-B", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-1-C", {scale = 0.5, shift = {0, -1}})
                        }
                    },
                    {
                        render_layer = "object-under",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-2", {scale = 0.5, shift = {0, -1}})
                        }
                    },
                    {
                        render_layer = "object",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-3", {scale = 0.5, shift = {0, -1}}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-shadow", {scale = 0.5, shift = {8, 0}, draw_as_shadow = true}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-emission-A", {scale = 0.5, shift = {0, -1}, draw_as_glow = true, blend_mode = "additive"}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-emission-B", {scale = 0.5, shift = {0, -1}, draw_as_glow = true, blend_mode = "additive"}),
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hubs/platform-hub-emission-C", {scale = 0.5, shift = {0, -1}, draw_as_glow = true, blend_mode = "additive"})
                        }
                    },
                    {
                        render_layer = "cargo-hatch",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hatches/platform-lower-hatch-occluder", {scale = 0.5, shift = {0, -1}})
                        }
                    },
                    {
                        render_layer = "above-inserters",
                        layers = {
                            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hatches/platform-upper-hatch-occluder", {scale = 0.5, shift = {0, -1}})
                        }
                    }
                }
            },
            cargo_station_parameters = {
                is_input_station = true,
                is_output_station = true,
                hatch_definitions = {
                    utils.platform_hatch({0.5, -3.5}, 2.25, 120, -0.5, 503),
                    utils.platform_hatch({2, -3.5}, 2.25, 120, -0.5, 504),
                    utils.platform_hatch({1.25, -2.5}, 1.25, 120, -1, 505),
                    utils.platform_hatch({-1.75, 0}, 2, 120, 0, 500),
                    utils.platform_hatch({-0.5, 0.5}, 1.5, 120, 0, 501),
                    utils.platform_hatch({-2, 1}, 1, 120, 0, 502),
                },
                giga_hatch_definitions = {} -- Заглушка, так как функций в utils для них нет
            },
            persistent_ambient_sounds = {
                base_ambience = {filename = "__space-age__/sound/wind/base-wind-space-platform.ogg", volume = 0.8},
                wind = {filename = "__space-age__/sound/wind/wind-space-platform.ogg", volume = 0.8},
                crossfade = {
                    order = {"wind", "base_ambience"},
                    curve_type = "cosine",
                    from = {control = 0.35, volume_percentage = 0.0},
                    to = {control = 2, volume_percentage = 100.0}
                }
            }
        },
    },
    item = {
        ["factory"] = {
            type = "item",
            name = nil,
            icon = nil,
            icon_size = 64,
            subgroup = "storage",
            order = "a[items]-z[nil-instantiated]",
            place_result = nil,
            stack_size = 50,
        },
        ["space-platform-hub"] = {
            type = "space-platform-starter-pack",
            name = nil,
            icon = "__space-age__/graphics/icons/space-platform-starter-pack.png",
            subgroup = "space-rocket",
            order = "b[space-platform-starter-pack]",
            inventory_move_sound = item_sounds.mechanical_large_inventory_move,
            pick_sound = item_sounds.mechanical_large_inventory_pickup,
            drop_sound = item_sounds.mechanical_large_inventory_move,
            stack_size = 1,
            weight = 1000000, -- 1 ton
            surface = "space-platform",
            trigger = {
                {
                    type = "direct",
                    action_delivery = {
                        type = "instant",
                        source_effects = {
                            {
                                type = "create-entity",
                                entity_name = nil
                            }
                        }
                    }
                }
            },
            initial_items = {{type = "item", name = "space-platform-foundation", amount = 100}},
            create_electric_network = true,
        }
    },
    item_instantiated = {
        ["factory"] = {
            type = "item-with-tags",
            name = nil,
            localised_name = nil,
            icons = {
                { icon = nil, icon_size = nil },
                { icon = F .. "/graphics/icon/packing-tape.png", icon_size = 64 }
            },
            subgroup = "factorissimo2",
            order = "b-a",
            place_result = nil,
            stack_size = 1,
            weight = 1000000,
            flags = {"not-stackable"},
            hidden_in_factoriopedia = true,
            factoriopedia_alternative = nil
        },
    },
    recipe = {
        type = "recipe",
        name = nil,
        enabled = false,
        energy_required = 30,
        ingredients = nil,
        results = {{type = "item", name = nil, amount = 1}},
        main_product = nil,
        category = data.raw["recipe-category"]["metallurgy-or-assembling"] and "metallurgy-or-assembling" or nil
    },
    technology = {
        type = "technology",
        name = nil,
        icon = nil,
        icon_size = nil,
        prerequisites = nil,
        effects = nil,
        unit = {
            count = nil,
            ingredients = nil,
            time = nil
        },
        order = nil,
    },
    tile = {
        type = "tile",
        -- subgroup = "factorissimo-tiles",
        name = nil,
        localised_name = nil,
        needs_correction = false,
        collision_mask = nil,
        variants = {
            main = {
                {
                    picture = F .. "/graphics/tile/factory-floor-1.png",
                    count = 16,
                    size = 1
                },
                {
                    picture = F .. "/graphics/tile/factory-floor-2.png",
                    count = 4,
                    size = 2,
                    probability = 0.39
                },
                {
                    picture = F .. "/graphics/tile/factory-floor-4.png",
                    count = 4,
                    size = 4,
                    probability = 1
                },
            },
            empty_transitions = true,
        },
        layer = 50,
        walking_speed_modifier = 2,
        layer_group = "ground-artificial",
        mined_sound = sounds.deconstruct_bricks(0.8),
        driving_sound = concrete_driving_sound,
        build_sound = concrete_tile_build_sounds,
        scorch_mark_color = {r = 0.373, g = 0.307, b = 0.243, a = 1.000},
        vehicle_friction_modifier = concrete_vehicle_friction_modifier,
        trigger_effect = tile_trigger_effects.concrete_trigger_effect(),
        map_color = nil,
    },
    data_bank = {
        type = "item-request",
        name = nil,
        icon = "__base__/graphics/icons/steel-chest.png",
        icon_size = 64,
        localised_description = {"storage-data-bank-description"},
    }
}

function base_prototypes.get_entity_types()
    local types = {}
    for _, value in pairs(base_prototypes.entity) do
        table.insert(types, value.type)
    end
    return types
end

return base_prototypes