local F = "__FactorissimoLib__"

if data then

    local tile_trigger_effects = require("__base__.prototypes.tile.tile-trigger-effects")
    local sounds = require("__base__.prototypes.entity.sounds")
    local item_sounds = require("__base__.prototypes.item_sounds")

    local concrete_vehicle_friction_modifier = data.raw["tile"]["concrete"].vehicle_friction_modifier
    local concrete_driving_sound = table.deepcopy(data.raw["tile"]["concrete"].driving_sound)
    local concrete_tile_build_sounds = table.deepcopy(data.raw["tile"]["concrete"].build_sound)

    local utils = require("__FactorissimoLib__/lib/prototype-utils")

    local function empty_circuit_wire_points()
        return {
            shadow = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}, 
            wire = {red = {0, 0}, green = {0, 0}, copper = {0, 0}}
        }
    end
    
    local base_prototypes = {
        entity = {
            ["factory"] = {
                type = "storage-tank",
                name = nil,
                icon = nil,
                icon_size = nil,
                flags = {"player-creation", "placeable-player"},
                minable = {mining_time = 0.5, result = "nil-instantiated", count = 1},
                subgroup = "factorissimo-factories",
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
                icon = "__space-age__/graphics/icon/space-platform-hub.png",
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
                subgroup = "factorissimo-factories",
                order = "a[items]-z[nil-instantiated]",
                place_result = nil,
                stack_size = 50,
            },
            ["space-platform-hub"] = {
                type = "space-platform-starter-pack",
                name = nil,
                icon = "__space-age__/graphics/icon/space-platform-starter-pack.png",
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
                subgroup = "factorissimo-factories",
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
                subgroup = "factorissimo-factories",
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
            effects = {
                type = "unlock-recipe",
                recipe = nil,
            },
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
            subgroup = "factorissimo-tiles",
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
            type = "item",
            name = nil,
            icon = "__core__/graphics/empty.png",
            icon_size = 1,
            localised_description = {"factorissimo.storage-data-bank-description"},
            flags = {"not-stackable", "only-in-cursor"}, 
            hidden = true,
            subgroup = "other",
            order = "z[factorissimo]-z[storage]",
            stack_size = 1
        },
        energy_interface = {
            type = "electric-energy-interface",
            name = nil, -- Устанавливается при создании
            icon = "__base__/graphics/icons/accumulator.png",
            icon_size = 64,
            flags = {"not-on-map", "hide-alt-info", "not-blueprintable", "not-deconstructable", "placeable-off-grid"},
            subgroup = "factorissimo-energy-interfaces",
            selection_priority = 1,
            minable = nil,
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
            selection_box = nil, -- Устанавливается при создании
            collision_box = nil, -- Устанавливается при создании
            collision_mask = {layers = {}}, 
            localised_name = {""},
        },
        connection_indicator = {
            type = "storage-tank",
            name = nil,
            flags = {"not-on-map", "player-creation", "not-deconstructable", "placeable-off-grid"},
            subgroup = "factorissimo-connection-indicators",
            max_health = 500,
            selection_box = {{-0.4, -0.4}, {0.4, 0.4}},
            collision_box = {{-0.4, -0.4}, {0.4, 0.4}},
            collision_mask = {not_colliding_with_itself = true, layers = {}},
            fluid_box = {
                volume = 1,
                pipe_connections = {},
            },
            window_bounding_box = {{0, 0}, {0, 0}},
            hidden = true,
            selection_priority = 52,
            pictures = {
                picture = {
                    sheet = {
                        filename = nil, -- Устанавливается динамически
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
        },
        factory_power_pole = {
            type = "electric-pole",
            name = nil,
            minable = nil,
            max_health = 500,
            flags = {"not-on-map", "placeable-off-grid"},
            selection_box = {{-1, -1}, {1, 1}},
            collision_box = {{-1, -1}, {1, 1}},
            subgroup = "factorissimo-parts",
            auto_connect_up_to_n_wires = 0,
            hidden = true,
            maximum_wire_distance = 1,
            supply_area_distance = 63,
            connection_points = {empty_circuit_wire_points(), empty_circuit_wire_points(), empty_circuit_wire_points(), empty_circuit_wire_points()},
        },
        horizontal_entrance_door = {
            type = "simple-entity-with-force",
            name = nil,
            icon = "__FactorissimoLib__/graphics/icon/factory-subicon.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation", "not-repairable", "not-on-map", "placeable-off-grid", "not-rotatable"},
            selectable_in_game = true,
            minable = nil,
            subgroup = "factorissimo-parts",
            max_health = 500,
            collision_box = {{nil, -0.4}, {nil, 0.4}}, 
            collision_mask = {layers = {}},
            selection_box = {{nil, -0.5}, {nil, 0.5}},
            render_layer = "object",
            picture = {
                filename = "__core__/graphics/empty.png",
                width = 1,
                height = 1,
            }
        },
        vertical_entrance_door = {
            type = "simple-entity-with-force",
            name = nil,
            icon = "__FactorissimoLib__/graphics/icon/factory-subicon.png",
            icon_size = 64,
            flags = {"placeable-neutral", "player-creation", "not-repairable", "not-on-map", "placeable-off-grid", "not-rotatable"},
            selectable_in_game = true,
            minable = nil,
            subgroup = "factorissimo-parts",
            max_health = 500,
            collision_box = {{-0.4, nil}, {0.4, nil}},
            collision_mask = {layers = {}}, -- Чтобы игрок проходил насквозь
            selection_box = {{-0.5, nil}, {0.5, nil}},
            render_layer = "object",
            picture = {
                filename = "__core__/graphics/empty.png",
                width = 1,
                height = 1,
            }
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
end

return {}