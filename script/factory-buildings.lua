local get_factory_by_building = remote_api.get_factory_by_building
local find_surrounding_factory = remote_api.find_surrounding_factory

local has_layout = has_layout

-- INITIALIZATION --

local dynamic_surface_factories = {
    "space-platform-hub-building-tier-1",
    "space-platform-hub-building-tier-2",
}

local function get_base_entity_name(name)
    -- Эта функция должна извлекать "factory" из "factory-nauvis" или "factory-aquilo"
    -- Простейший вариант: удалить все после последнего дефиса
    local base_name = name:match("^(.*)%-.*$")
    return base_name or name
end

factorissimo.on_event(factorissimo.events.on_init(), function()
    -- List of all factories
    storage.factories = storage.factories or {}
    -- Map: Id from item-with-tags -> Factory
    storage.saved_factories = storage.saved_factories or {}
    -- Map: Entity unit number -> Factory it is a part of
    storage.factories_by_entity = storage.factories_by_entity or {}
    -- Map: Surface index -> list of factories on it
    storage.surface_factories = storage.surface_factories or {}
    -- Scalar
    storage.next_factory_surface = storage.next_factory_surface or 0
end)

-- RECURSION TECHNOLOGY --

local function was_this_placed_on_a_space_exploration_spaceship(layout, building)
    local surface = building.surface

    if not script.active_mods["space-exploration"] then
        return false
    end

    if layout.surface_override ~= "space-factory-floor" then
        return false
    end

    if surface.name == "se-spaceship-factory-floor" then -- recursion
        return true
    end

    local x, y = building.position.x, building.position.y
    local D = layout.outside_size / 2
    local area = {{x - D, y - D}, {x + D, y + D}}
    return 1 == surface.count_tiles_filtered {
        area = area,
        name = "se-spaceship-floor",
        limit = 1,
    }
end

--- @param surface LuaSurface|LuaPlanet
--- @return string
local function true_name(surface)
    if surface.name:find("%-factory%-floor$") then
        return surface.name:gsub("%-factory%-floor$", "")
    elseif (surface.object_name or type(surface)) == "LuaSurface" then
        if surface.planet or surface.platform then
            return surface.planet.name
        end
    end
    return surface.name:gsub("%-%d+$", "")
end

local function set_factory_active_or_inactive(factory)
    local building = factory.building
    if not building or not building.valid then
        factory.inactive = false
        return
    end
    local surface = building.surface
    local position = building.position

    local function can_place_factory_here()
        -- Check if a player is trying to cheat by moving factories to diffrent planets.
        local original_planet = factory.original_planet
        local inside_surface = factory.inside_surface

        if original_planet and original_planet.valid then
            if inside_surface and inside_surface.valid and inside_surface.name ~= "se-spaceship-factory-floor" then
                local original_planet_name = true_name(original_planet)
                local surface_name = true_name(surface)
                if original_planet_name ~= surface_name then
                    local original_planet_prototype = (game.planets[original_planet_name] or original_planet).prototype
                    local flying_text = {"factory-connection-text.invalid-placement-planet", original_planet_name, original_planet_prototype.localised_name}
                    return false, flying_text, true
                end
            end
        end

        -- In space exploration, we differentiate between space factories and spaceship factories.
        if script.active_mods["space-exploration"] then
            if inside_surface and inside_surface.valid then
                local spaceship = was_this_placed_on_a_space_exploration_spaceship(factory.layout, building)
                if inside_surface.name == "space-factory-floor" and spaceship then
                    return false, {"factory-connection-text.se-must-not-build-factory-building-on-a-spaceship"}, true
                end
            end
        end

        if settings.global["Factorissimo2-free-recursion"].value then
            return true
        end

        local surrounding_factory = find_surrounding_factory(surface, position)
        if not surrounding_factory then
            return true
        end

        local has_tech_t2 = surrounding_factory.force.technologies["factory-recursion-t2"].researched
        local has_tech_t1 = has_tech_t2 or surrounding_factory.force.technologies["factory-recursion-t1"].researched

        local inner_tier = factory.layout.tier
        local outer_tier = surrounding_factory.layout.tier
        if not has_tech_t2 and inner_tier >= outer_tier then
            return false, {"factory-connection-text.invalid-placement-recursion-2"}, false
        end

        if not has_tech_t1 then -- cannot do any recursion
            return false, {"factory-connection-text.invalid-placement-recursion-1"}, false
        end

        return true
    end

    local can_place, msg, cancel_creation = can_place_factory_here()

    factory.inactive = not can_place
    if can_place then return end
    assert(msg)

    -- TODO: vanilla bug; `player.mine_entity` does not respect event.buffer
    -- if cancel_creation and storage.player_index then
    --     local player = game.get_player(storage.player_index)
    --     player.mine_entity(building, false)
    -- end
    factorissimo.create_flying_text {position = position, text = msg}
    if not factory.connections then return end
    for cid, _ in pairs(factory.layout.connections) do
        local conn = factory.connections[cid]
        factorissimo.destroy_connection(conn)
    end
end

require "lights"
require "greenhouse"
require "roboport"
require "overlay"

local DEFAULT_FACTORY_UPGRADES = {
    {"factorissimo", "build_lights_upgrade"},
    {"factorissimo", "build_greenhouse_upgrade"},
    {"factorissimo", "build_display_upgrade"},
    -- {"factorissimo", "build_roboport_upgrade"}
}

local function build_factory_upgrades(factory)
    for _, upgrade in pairs(factory.layout.upgrades or DEFAULT_FACTORY_UPGRADES) do
        assert(#upgrade == 2)
        local mod, upgrade_function = upgrade[1], upgrade[2]
        if mod == "factorissimo" then
            if not factorissimo[upgrade_function] then
                error("Missing factory upgrade function: " .. upgrade_function)
            end
            factorissimo[upgrade_function](factory)
        else
            remote.call(mod, upgrade_function, factory)
        end
    end
end

--- If a factory factory is built without proper recursion technology, it will be inactive.
--- This function reactivates these factories once the research is complete.
local function activate_factories()
    for _, factory in pairs(storage.factories) do
        set_factory_active_or_inactive(factory)
        build_factory_upgrades(factory)
    end
end
factorissimo.on_event(factorissimo.events.on_init(), activate_factories)

factorissimo.on_event({defines.events.on_research_finished, defines.events.on_research_reversed}, function(event)
    if not storage.factories then return end -- In case any mod or scenario script calls LuaForce.research_all_technologies() during its on_init
    local name = event.research.name
    if name == "factory-recursion-t1" or name == "factory-recursion-t2" then
        activate_factories()
    else
        for _, factory in pairs(storage.factories) do build_factory_upgrades(factory) end
    end
end)

local function update_recursion_techs(force)
    if settings.global["Factorissimo2-hide-recursion"] and settings.global["Factorissimo2-hide-recursion"].value then
        if force.technologies["factory-recursion-t2"] then
            force.technologies["factory-recursion-t2"].enabled = false
        end
    elseif settings.global["Factorissimo2-hide-recursion-2"] and settings.global["Factorissimo2-hide-recursion-2"].value then
        if force.technologies["factory-recursion-t2"] then
            force.technologies["factory-recursion-t2"].enabled = false
        end
    else
        if force.technologies["factory-recursion-t1"] then
            force.technologies["factory-recursion-t1"].enabled = true
        end
        if force.technologies["factory-recursion-t2"] then
            force.technologies["factory-recursion-t2"].enabled = true
        end
    end
end

factorissimo.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
    if event.setting_type == "runtime-global" then activate_factories() end

    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

factorissimo.on_event(defines.events.on_force_created, function(event)
    local force = event.force
    update_recursion_techs(force)
end)

factorissimo.on_event(factorissimo.events.on_init(), function()
    for _, force in pairs(game.forces) do
        update_recursion_techs(force)
    end
end)

-- FACTORY GENERATION --

local function get_planet_name_from_hub(building_name, prefixes)
    for _, prefix in ipairs(prefixes) do
        -- Ищем префикс в начале имени (с использованием plain=true для поиска без шаблонов)
        if building_name:find(prefix, 1, true) == 1 then
            -- Префикс найден. Извлекаем остаток, который должен быть "-[имя_планеты]"
            local suffix = building_name:sub(#prefix + 1)
            
            -- Проверяем, что это не базовое имя и суффикс начинается с дефиса "-"
            if #suffix > 0 and suffix:sub(1, 1) == "-" then
                -- Возвращаем имя планеты, удаляя начальный дефис
                return suffix:sub(2)
            end
        end
    end
    return nil
end

local function which_void_surface_should_this_new_factory_be_placed_on(layout, building)
    if was_this_placed_on_a_space_exploration_spaceship(layout, building) then
        return "se-spaceship-factory-floor"
    end
    if layout.surface_override then return layout.surface_override end

    local surface = building.surface
    local building_name = building.name
    
    -- НОВАЯ ЛОГИКА: ПРОВЕРКА НА ДИНАМИЧЕСКИЙ ХАБ ПЛАТФОРМЫ
    local planet_name = get_planet_name_from_hub(building_name, dynamic_surface_factories)
    
    if planet_name then
        -- Если имя планеты найдено (например, "aquilo"), возвращаем:
        return (planet_name .. "-factory-floor")
    end
    
    -- ИСПРАВЛЕНИЕ: ПРОВЕРКА НА КОСМИЧЕСКУЮ ПЛАТФОРМУ
    if surface.platform and surface.platform.valid then
        -- Используем имя платформы (например, "platform-3") для создания уникального имени.
        return (surface.platform.index .. "-factory-floor")
    end
    
    if surface.planet then
        -- Логика для Factorissimo-фабрик, размещенных на планете (например, factory-nauvis)
        -- Добавленный gsub предотвращает дублирование "-factory-floor"
        return (surface.planet.name .. "-factory-floor"):gsub("%-factory%-floor%-factory%-floor", "-factory-floor")
    end

    storage.next_factory_surface = storage.next_factory_surface + 1
    return storage.next_factory_surface .. "-factory-floor"
end

factorissimo.on_event(defines.events.on_surface_created, function(event)
    local surface = game.get_surface(event.surface_index)
    if not surface.name:find("%-factory%-floor$") then return end

    local mgs = surface.map_gen_settings
    mgs.width = 2
    mgs.height = 2
    surface.map_gen_settings = mgs
end)

--- searches a factory floor for "holes" where a new factory could be created
--- else returns the next position
local function find_first_unused_position(surface)
    local used_indexes = {}
    for k in pairs(storage.surface_factories[surface.index] or {}) do
        table.insert(used_indexes, k)
    end
    table.sort(used_indexes)

    for i, index in pairs(used_indexes) do
        if i ~= index then -- found a gap
            return (used_indexes[i - 1] or 0) + 1
        end
    end

    return #used_indexes + 1
end

local function create_factory_position(layout, building)
    local surface_name = which_void_surface_should_this_new_factory_be_placed_on(layout, building)
    local surface = game.get_surface(surface_name)

    -- 1. Подготовка поверхности
    if surface then
        local mgs = surface.map_gen_settings
        mgs.width = 2
        mgs.height = 2
        surface.map_gen_settings = mgs
    else
        local planet = game.planets[surface_name]
        if planet then
            surface = planet.surface or planet.create_surface()
        else
            surface = game.create_surface(surface_name, {width = 2, height = 2})
            local surface_number = surface_name:match("^(%d+)%-factory%-floor$")
            if surface_number then
                surface.localised_name = {"space-location-name.factory-floor", surface_number}
            end
        end
        surface.daytime = 0.5
        surface.freeze_daytime = true
    end

    -- 2. Расчет КВАДРАТНОЙ СПИРАЛИ
    -- n - индекс текущей фабрики (1, 2, 3...)
    local n = find_first_unused_position(surface)
    
    local x, y = 0, 0
    if n > 1 then
        -- Сдвигаем n на -1 для удобства расчетов (первая в 0,0)
        local i = n - 1
        -- Математика квадратной спирали (Step-by-step)
        local root = math.floor(math.sqrt(i))
        local side = math.floor((root + 1) / 2)
        local max_in_square = (2 * side + 1) ^ 2
        local inner_side = 2 * side
        
        if i <= (2 * side - 1) ^ 2 + inner_side then -- Правая сторона
            x = side; y = i - ((2 * side - 1) ^ 2 + side - 1) - side
        elseif i <= (2 * side - 1) ^ 2 + 2 * inner_side then -- Верхняя сторона
            x = side - (i - ((2 * side - 1) ^ 2 + inner_side)); y = side
        elseif i <= (2 * side - 1) ^ 2 + 3 * inner_side then -- Левая сторона
            x = -side; y = side - (i - ((2 * side - 1) ^ 2 + 2 * inner_side))
        else -- Нижняя сторона
            x = -side + (i - ((2 * side - 1) ^ 2 + 3 * inner_side)); y = -side
        end
    end

    -- 3. Наложение сетки (16 чанков между центрами)
    local FACTORISSIMO_CHUNK_SPACING = 16 
    local cx = x * FACTORISSIMO_CHUNK_SPACING
    local cy = y * FACTORISSIMO_CHUNK_SPACING

    -- 4. Генерация чанков (запас под большие фабрики 400x400)
    -- 400 тайлов / 32 = 12.5 чанков. Радиус 8 покрывает 16 чанков.
    local gen_radius = 8
    for xx = -gen_radius, gen_radius do
        for yy = -gen_radius, gen_radius do
            surface.set_chunk_generated_status({cx + xx, cy + yy}, defines.chunk_generated_status.entities)
        end
    end

    -- 5. Очистка территории от травы/декораций
    local area_limit = (FACTORISSIMO_CHUNK_SPACING * 32) / 2
    surface.destroy_decoratives {
        area = {
            {32 * cx - area_limit, 32 * cy - area_limit}, 
            {32 * cx + area_limit, 32 * cy + area_limit}
        }
    }
    
    factorissimo.spawn_maraxsis_water_shaders(surface, {x = cx, y = cy})

    -- 6. Инициализация объекта фабрики
    local factory = {}
    factory.inside_surface = surface
    factory.inside_x = 32 * cx
    factory.inside_y = 32 * cy
    factory.inside_pos = {
        x = factory.inside_x,
        y = factory.inside_y
    }
    factory.stored_pollution = 0
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_door_x = factory.outside_x + layout.outside_door_x
    factory.outside_door_y = factory.outside_y + layout.outside_door_y
    factory.outside_surface = building.surface

    -- 7. Сохранение данных
    storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
    storage.surface_factories[surface.index][n] = factory

    local highest_id = 0
    for id in pairs(storage.factories) do
        if id > highest_id then highest_id = id end
    end
    factory.id = highest_id + 1
    storage.factories[factory.id] = factory

    return factory
end

local function add_tile_rect(tiles, tile_name, xmin, ymin, xmax, ymax) -- tiles is rw
    local i = #tiles
    for x = xmin, xmax - 1 do
        for y = ymin, ymax - 1 do
            i = i + 1
            tiles[i] = {name = tile_name, position = {x, y}}
        end
    end
end

local function add_hidden_tile_rect(factory)
    local surface = factory.inside_surface
    local layout = factory.layout
    local xmin = factory.inside_x - 64
    local ymin = factory.inside_y - 64
    local xmax = factory.inside_x + 64
    local ymax = factory.inside_y + 64

    local position = {0, 0}
    for x = xmin, xmax - 1 do
        for y = ymin, ymax - 1 do
            position[1] = x
            position[2] = y
            surface.set_hidden_tile(position, "water")
        end
    end
end

local function add_tile_mosaic(tiles, tile_name, xmin, ymin, xmax, ymax, pattern) -- tiles is rw
    local i = #tiles
    for x = 0, xmax - xmin - 1 do
        for y = 0, ymax - ymin - 1 do
            if (string.sub(pattern[y + 1], x + 1, x + 1) == "+") then
                i = i + 1
                tiles[i] = {name = tile_name, position = {x + xmin, y + ymin}}
            end
        end
    end
end

local function create_factory_interior(layout, building)
    local force = building.force

    local factory = create_factory_position(layout, building)
    factory.building = building
    factory.layout = layout
    factory.force = force
    factory.quality = building.quality
    
    -- Корректируем координаты двери: смещаем на 1 тайл "наружу" (ниже для южной стороны)
    -- Для универсальности добавим смещение в зависимости от стороны
    local side = layout.factory_data.door.side
    local dx, dy = 0, 0
    if side == "s" then dy = 1
    elseif side == "n" then dy = -1
    elseif side == "e" then dx = 1
    elseif side == "w" then dx = -1
    end

    factory.inside_door_x = layout.inside_door_x + factory.inside_x + dx
    factory.inside_door_y = layout.inside_door_y + factory.inside_y + dy

    local tile_name_mapping = {}
    if factory.inside_surface.name == "se-spaceship-factory-floor" then
        tile_name_mapping["space-factory-floor"] = "se-spaceship-factory-floor"
        tile_name_mapping["space-factory-entrance"] = "se-spaceship-factory-entrance"
    end

    -- ... (код генерации тайлов без изменений) ...
    local orig_tiles = remote_api.create_factory_tiles(layout.factory_data)
    local tiles = {}
    for _, t in ipairs(orig_tiles) do
        local tile_name = tile_name_mapping[t.name] or t.name
        table.insert(tiles, {
            name = tile_name,
            position = {t.position[1] + factory.inside_x, t.position[2] + factory.inside_y}
        })
    end

    for _, cpos in pairs(layout.connections) do
        local tile_name = tile_name_mapping[layout.connection_tile] or layout.connection_tile
        table.insert(tiles, {
            name = tile_name, 
            position = {factory.inside_x + cpos.inside_x, factory.inside_y + cpos.inside_y}
        })
    end

    factory.inside_surface.set_tiles(tiles)

    -- Энергосеть: подстанция теперь будет на 3 тайла ниже центра
    factorissimo.get_or_create_inside_power_pole(factory)
    
    -- Если функция spawn_cerys_entities использует factory.inside_y, 
    -- убедись, что внутри неё координаты тоже учитывают этот сдвиг.
    -- Если мы хотим переопределить позицию здесь:
    if factory.power_pole then
        factory.power_pole.teleport({factory.inside_x, factory.inside_y + 3})
    end

    -- Радар и прочее
    local radar = factory.inside_surface.create_entity {
        name = "factorissimo-factory-radar",
        position = {factory.inside_x, factory.inside_y}, -- Радар оставляем в центре
        force = force,
    }
    radar.destructible = false

    -- Спавн двери (уже с учетом dx, dy)
    local door_name = (side == "e" or side == "w") and "factory-vertical-exit-door" or "factory-horizontal-exit-door"
    
    local door = factory.inside_surface.create_entity {
        name = door_name,
        position = {factory.inside_door_x, factory.inside_door_y},
        force = force,
        raise_built = true 
    }

    if door then
        door.destructible = false
        door.minable = false
        factory.exit_door = door
    end

    -- Обновляем карту
    factory.force.chart(factory.inside_surface, {
        {factory.inside_x - 32, factory.inside_y - 32}, 
        {factory.inside_x + 32, factory.inside_y + 32}
    })

    return factory
end

local function create_factory_door(factory, building)
    factorissimo.log("LOG: Start create_factory_door for " .. building.name)
    
    local layout = factory.layout
    if not (layout and layout.door) then 
        factorissimo.log("LOG: No layout or door found for factory")
        return 
    end

    -- Очистка старой двери
    if factory.entrance_door and factory.entrance_door.valid then
        factorissimo.log("LOG: Destroying old door")
        factory.entrance_door.destroy()
    end

    -- 1. Определяем имя сущности
    local side = layout.door.side
    local prefix = (side == "w" or side == "e") and "vertical" or "horizontal"
    local door_entity_name = prefix .. "-factory-entrance-door-" .. tostring(layout.door.size)

    -- 2. Рассчитываем позицию (середина двери на 0.2 тайла снаружи от края)
    local spawn_pos = {x = building.position.x, y = building.position.y}
    local b_proto = building.prototype
    
    -- Половина размера здания
    local h_w = b_proto.tile_width / 2
    local h_h = b_proto.tile_height / 2
    
    -- Смещение: край здания + 0.2
    local out_offset = 0.2

    if side == "n" then
        spawn_pos.y = spawn_pos.y - (h_h + out_offset)
    elseif side == "s" then
        spawn_pos.y = spawn_pos.y + (h_h + out_offset)
    elseif side == "w" then
        spawn_pos.x = spawn_pos.x - (h_w + out_offset)
    elseif side == "e" then
        spawn_pos.x = spawn_pos.x + (h_w + out_offset)
    end

    local door = building.surface.create_entity{
        name = door_entity_name,
        position = spawn_pos,
        force = building.force
    }
    
    if door then
        factorissimo.log("LOG: Door spawned successfully!")
        door.destructible = false
        storage.factories_by_entity[door.unit_number] = factory
        factory.entrance_door = door
    else
        factorissimo.log("LOG: FAILED to create entity! Check if " .. door_entity_name .. " exists in game.entity_prototypes")
    end
end


local function create_factory_exterior(factory, building)
    local layout = factory.layout
    local force = factory.force
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_door_x = factory.outside_x + layout.outside_door_x
    factory.outside_door_y = factory.outside_y + layout.outside_door_y
    factory.outside_surface = building.surface

    local oer = factory.outside_surface.create_entity {name = layout.outside_energy_receiver_type, position = {factory.outside_x, factory.outside_y}, force = force}
    oer.destructible = false
    oer.operable = false
    oer.rotatable = false
    factory.outside_energy_receiver = oer

    if factory.outside_surface.has_global_electric_network then
        local genp = factory.outside_surface.create_entity {name = "factory-global-electric-network-pole", position = {factory.outside_x, factory.outside_y}, force = force}
        genp.destructible = false
        genp.operable = false
        genp.rotatable = false
        factory.global_electric_network_pole = genp
    end

    factory.outside_overlay_displays = {}
    factory.outside_port_markers = {}

    storage.factories_by_entity[building.unit_number] = factory
    factory.building = building
    factory.built = true

    factorissimo.recheck_factory_connections(factory)
    factorissimo.update_power_connection(factory)
    factorissimo.update_overlay(factory)
    create_factory_door(factory, building)
    build_factory_upgrades(factory)
    return factory
end

-- FACTORY MINING AND DECONSTRUCTION --

local function cleanup_factory_exterior(factory, building)
    factorissimo.cleanup_outside_energy_receiver(factory)
    factorissimo.cleanup_factory_roboport_exterior_chest(factory)

    factorissimo.disconnect_factory_connections(factory)
    for _, render_id in pairs(factory.outside_overlay_displays) do
        local object = rendering.get_object_by_id(render_id)
        if object then object.destroy() end
    end
    factory.outside_overlay_displays = {}
    for _, render_id in pairs(factory.outside_port_markers) do
        local object = rendering.get_object_by_id(render_id)
        if object then object.destroy() end
    end
    factory.outside_port_markers = {}
    factory.building = nil
    factory.built = false
end

local sprite_path_translation = {
    virtual = "virtual-signal",
}
local function generate_factory_item_description(factory)
    local overlay = factory.inside_overlay_controller
    local params = {}
    if overlay and overlay.valid then
        for _, section in pairs(overlay.get_or_create_control_behavior().sections) do
            for _, filter in pairs(section.filters) do
                if filter.value and filter.value.name then
                    local sprite_type = sprite_path_translation[filter.value.type] or filter.value.type
                    table.insert(params, "[" .. sprite_type .. "=" .. filter.value.name .. "]")
                end
            end
        end
    end
    local params = table.concat(params, "\n")
    if params ~= "" then return "[font=heading-2]" .. params .. "[/font]" end
end

local function is_completely_empty(factory)
    local roboport_upgrade = factory.roboport_upgrade
    if roboport_upgrade then
        for _, entity in pairs {roboport_upgrade.storage, roboport_upgrade.roboport} do
            if entity and entity.valid then
                for i = 1, entity.get_max_inventory_index() do
                    local inventory = entity.get_inventory(i)
                    if not inventory.is_empty() then return false end
                end
            end
        end
    end

    local x, y = factory.inside_x, factory.inside_y
    local D = (factory.layout.inside_size + 8) / 2
    local area = {{x - D, y - D}, {x + D, y + D}}

    local interior_entities = factory.inside_surface.find_entities_filtered {area = area}
    for _, entity in pairs(interior_entities) do
        local collision_mask = entity.prototype.collision_mask.layers
        local is_hidden_entity = (not collision_mask) or table_size(collision_mask) == 0
        if not is_hidden_entity then return false end
    end
    return true
end

local function cleanup_factory_interior(factory)
    local x, y = factory.inside_x, factory.inside_y
    local D = (factory.layout.inside_size + 8) / 2
    local area = {{x - D, y - D}, {x + D, y + D}}

    for _, e in pairs(factory.inside_surface.find_entities_filtered {area = area}) do
        e.destroy()
    end

    local out_of_map_tiles = {}
    for xx = math.floor(x - D), math.ceil(x + D) do
        for yy = math.floor(y - D), math.ceil(y + D) do
            out_of_map_tiles[#out_of_map_tiles + 1] = {position = {xx, yy}, name = "out-of-map"}
        end
    end
    factory.inside_surface.set_tiles(out_of_map_tiles)

    local factory_lists = {storage.factories, storage.saved_factories, storage.factories_by_entity}
    for surface_index, factory_list in pairs(storage.surface_factories) do
        factory_lists[#factory_lists + 1] = factory_list
    end

    for _, factory_list in pairs(factory_lists) do
        for k, f in pairs(factory_list) do
            if f == factory then
                factory_list[k] = nil
            end
        end
    end

    for _, force in pairs(game.forces) do
        force.rechart(factory.inside_surface)
    end

    -- https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues/211
    storage.was_deleted = storage.was_deleted or {}
    storage.was_deleted[factory.id] = true

    for k in pairs(factory) do factory[k] = nil end
end

-- How players pick up factories
-- Working factory buildings don't return items, so we have to manually give the player an item
factorissimo.on_event({
    defines.events.on_player_mined_entity,
    defines.events.on_robot_mined_entity,
    defines.events.on_space_platform_mined_entity
}, function(event)
    local entity = event.entity
    if not has_layout(entity.name) then return end

    local factory = get_factory_by_building(entity)
    if not factory then return end
    cleanup_factory_exterior(factory, entity)

    if is_completely_empty(factory) then
        local buffer = event.buffer
        buffer.clear()
        buffer.insert {
            name = factory.layout.name,
            count = 1,
            quality = entity.quality,
            health = entity.health / entity.max_health
        }
        cleanup_factory_interior(factory)
        return
    end

    storage.saved_factories[factory.id] = factory
    local buffer = event.buffer
    buffer.clear()
    buffer.insert {
        name = factory.layout.name .. "-instantiated",
        count = 1,
        tags = {id = factory.id},
        custom_description = generate_factory_item_description(factory),
        quality = entity.quality,
        health = entity.health / entity.max_health
    }
    local item_stack = buffer[1]
    assert(item_stack.valid_for_read and item_stack.is_item_with_tags)
    local item = item_stack.item
    assert(item and item.valid)
    factory.item = item
end)

local function prevent_factory_mining(entity)
    local factory = get_factory_by_building(entity)
    if not factory then return end
    storage.factories_by_entity[entity.unit_number] = nil
    local entity = entity.surface.create_entity {
        name = entity.name,
        position = entity.position,
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
        player = entity.last_user
    }
    storage.factories_by_entity[entity.unit_number] = factory
    factory.building = entity
    factorissimo.update_overlay(factory)
    if #factory.outside_port_markers ~= 0 then
        factory.outside_port_markers = {}
        factorissimo.toggle_port_markers(factory)
    end
    factorissimo.create_flying_text {position = entity.position, text = {"factory-cant-be-mined"}}
end

local fake_robots = {["repair-block-robot"] = true} -- Modded construction robots with heavy control scripting
factorissimo.on_event(defines.events.on_robot_pre_mined, function(event)
    local entity = event.entity
    if has_layout(entity.name) and fake_robots[event.robot.name] then
        prevent_factory_mining(entity)
        entity.destroy()
    elseif entity.type == "item-entity" and entity.stack.valid_for_read and has_layout(entity.stack.name) then
        event.robot.destructible = false
    end
end)

-- How biters pick up factories
-- Too bad they don't have hands
factorissimo.on_event(defines.events.on_entity_died, function(event)
    local entity = event.entity
    if not has_layout(entity.name) then return end
    local factory = get_factory_by_building(entity)
    if not factory then return end

    storage.saved_factories[factory.id] = factory
    cleanup_factory_exterior(factory, entity)

    local items = entity.surface.spill_item_stack {
        position = entity.position,
        stack = {
            name = factory.layout.name .. "-instantiated",
            tags = {id = factory.id},
            quality = entity.quality.name,
            count = 1,
            custom_description = generate_factory_item_description(factory)
        },
        enable_looted = false,
        force = nil,
        allow_belts = false,
        max_radius = 0,
        use_start_position_on_failure = true
    }
    assert(table_size(items) == 1, "Failed to generate factory item. Are you using the quantum-fabricator mod? See https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues/203")
    local item = items[1].stack.item
    assert(item and item.valid)
    factory.item = item
    entity.force.print {"factory-killed-by-biters", items[1].gps_tag}
end)

factorissimo.on_event(defines.events.on_post_entity_died, function(event)
    if not has_layout(event.prototype.name) or not event.ghost then return end
    local factory = storage.factories_by_entity[event.unit_number]
    if not factory then return end
    event.ghost.tags = {id = factory.id}
end)

-- Just rebuild the factory in this case
factorissimo.on_event(defines.events.script_raised_destroy, function(event)
    local entity = event.entity
    if has_layout(entity.name) then
        prevent_factory_mining(entity)
    end
end)

local function on_delete_surface(surface)
    storage.surface_factories[surface.index] = nil

    local childen_surfaces_to_delete = {}
    for _, factory in pairs(storage.factories) do
        local inside_surface = factory.inside_surface
        local outside_surface = factory.outside_surface
        if inside_surface.valid and outside_surface.valid and factory.outside_surface == surface then
            childen_surfaces_to_delete[inside_surface.index] = inside_surface
        end
    end

    for _, factory_list in pairs {storage.factories, storage.saved_factories, storage.factories_by_entity} do
        for k, factory in pairs(factory_list) do
            local inside_surface = factory.inside_surface
            if not inside_surface.valid or childen_surfaces_to_delete[inside_surface.index] then
                factory_list[k] = nil
            end
        end
    end

    for _, child_surface in pairs(childen_surfaces_to_delete) do
        on_delete_surface(child_surface)
        game.delete_surface(child_surface)
    end
end

-- Delete all children surfaces in this case.
factorissimo.on_event(defines.events.on_pre_surface_cleared, function(event)
    on_delete_surface(game.get_surface(event.surface_index))
end)

-- FACTORY PLACEMENT AND INITALIZATION --

local function create_fresh_factory(entity)
    game.print("Creating fresh factory for " .. entity.name .. " at " .. serpent.line(entity.position))
    local layout = remote_api.create_layout(entity.name, entity.quality)
    local factory = create_factory_interior(layout, entity)
    create_factory_exterior(factory, entity)
    factory.original_planet = entity.surface.planet
    set_factory_active_or_inactive(factory)
    return factory
end

-- It's possible that the item used to build this factory is not the same as the one that was saved.
-- In this case, clear tags and description of the saved item such that there is only 1 copy of the factory item.
-- https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues/155
local function handle_factory_control_xed(factory)
    local item = factory.item
    if not item or not item.valid then return end
    factory.item.tags = {}
    factory.item.custom_description = factory.item.prototype.localised_description

    -- We should also attempt to swapped the packed factory item with an unpacked.
    -- If this fails, whatever. It's just to avoid confusion. A packed factory with no tags is equal to an unpacked factory.
    local item_stack = item.item_stack
    if not item_stack or not item_stack.valid_for_read then return end

    item_stack.set_stack {
        name = item.name:gsub("%-instantiated$", ""),
        count = item_stack.count,
        quality = item_stack.quality,
        health = item_stack.health,
    }
end

local function handle_factory_placed(entity, tags)
    if not tags or not tags.id then
        create_fresh_factory(entity)
        return
    end

    local factory = storage.saved_factories[tags.id]
    storage.saved_factories[tags.id] = nil
    if factory and factory.inside_surface and factory.inside_surface.valid then
        -- This is a saved factory, we need to unpack it
        factory.quality = entity.quality
        create_factory_exterior(factory, entity)
        set_factory_active_or_inactive(factory)
        handle_factory_control_xed(factory)
        return
    end

    if not factory and storage.factories[tags.id] then
        -- This factory was copied from somewhere else. Clone all contained entities
        local factory = create_fresh_factory(entity)
        factorissimo.copy_entity_ghosts(storage.factories[tags.id], factory)
        factorissimo.update_overlay(factory)
        return
    end

    -- https://github.com/notnotmelon/factorissimo-2-notnotmelon/issues/211
    if storage.was_deleted and storage.was_deleted[tags.id] then
        create_fresh_factory(entity)
        return
    end

    factorissimo.create_flying_text {position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
    entity.destroy()
end

factorissimo.on_event(factorissimo.events.on_built(), function(event)
    local entity = event.entity
    if not entity.valid then return end
    local entity_name = entity.name

    if has_layout(entity_name) then
        local inventory = event.consumed_items
        local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
        handle_factory_placed(entity, tags)
        return
    end

    if entity.type ~= "entity-ghost" then return end
    local ghost_name = entity.ghost_name

    if has_layout(ghost_name) and entity.tags then
        local copied_from_factory = storage.factories[entity.tags.id]
        if copied_from_factory then
            factorissimo.update_overlay(copied_from_factory, entity)
        end
    end
end)

local function init_space_platform_with_factory(surface_name)
    local surface = game.surfaces[surface_name]
    if not surface or not surface.valid then return end
    local platform = surface.platform

    if platform and platform.hub and platform.hub.valid and has_layout(platform.hub.name) then
        handle_factory_placed(platform.hub, nil)
    end
end

factorissimo.register_delayed_function('init_space_platform_with_factory', init_space_platform_with_factory)

factorissimo.on_event(defines.events.on_surface_created, function(event)
    local surface = game.surfaces[event.surface_index]
    
    if surface and surface.platform then
        factorissimo.execute_later('init_space_platform_with_factory', 10, surface.name)
    end
end)

-- How to clone your factory
-- This implementation will not actually clone factory buildings, but move them to where they were cloned.
local clone_forbidden_prefixes = {
    "factory-1-",
    "factory-2-",
    "factory-3-",
    "space-factory-1-",
    "space-factory-2-",
    "space-factory-3-",
    "factory-power-input-",
    "factory-connection-indicator-",
    "factory-power-pole",
    "factory-overlay-controller",
    "factory-port-marker",
    "factory-blueprint-anchor",
    "factory-fluid-dummy-connector-",
    "factory-linked-",
    "factory-requester-chest-",
    "factory-eject-chest-",
    "factory-construction-chest",
    "factory-construction-roboport",
    "factory-hidden-construction-robot",
    "factory-hidden-construction-roboport",
    "factory-hidden-radar-",
    "factorissimo-factory-radar-",
    "factory-heat-dummy-connector",
    "factory-inside-pump-input",
    "factory-inside-pump-output",
    "factory-outside-pump-input",
    "factory-outside-pump-output",
}

local function is_entity_clone_forbidden(name)
    for _, prefix in pairs(clone_forbidden_prefixes) do
        if name:sub(1, #prefix) == prefix then
            return true
        end
    end
    return false
end

factorissimo.on_event(defines.events.on_entity_cloned, function(event)
    local src_entity = event.source
    local dst_entity = event.destination
    if is_entity_clone_forbidden(dst_entity.name) then
        dst_entity.destroy()
    elseif has_layout(src_entity.name) then
        local factory = get_factory_by_building(src_entity)
        cleanup_factory_exterior(factory, src_entity)
        if src_entity.valid then src_entity.destroy() end
        create_factory_exterior(factory, dst_entity)
        set_factory_active_or_inactive(factory)
    end
end)

-- MISC --

commands.add_command("give-lost-factory-buildings", {"command-help-message.give-lost-factory-buildings"}, function(event)
    local player = game.get_player(event.player_index)
    if not (player and player.connected and player.admin) then return end
    local inventory = player.get_main_inventory()
    if not inventory then return end
    for id, factory in pairs(storage.saved_factories) do
        for i = 1, #inventory do
            local stack = inventory[i]
            if stack.valid_for_read and stack.name == factory.layout.name and stack.type == "item-with-tags" and stack.tags.id == id then goto found end
        end
        player.insert {name = factory.layout.name .. "-instantiated", count = 1, tags = {id = id}}
        ::found::
    end
end)

factorissimo.on_event(defines.events.on_forces_merging, function(event)
    for _, factory in pairs(storage.factories) do
        if not factory.force.valid then
            factory.force = game.forces["player"]
        end
        if factory.force.name == event.source.name then
            factory.force = event.destination
        end
    end
end)

-- Fallback definitions for development
if not game then
    game = {
        forces = {},
        get_surface = function() return {} end,
    }
end

if not settings then
    settings = {
        global = {
            ["Factorissimo2-hide-recursion"] = {value = false},
            ["Factorissimo2-hide-recursion-2"] = {value = false},
        }
    }
end

if not remote then
    remote = {
        interfaces = {},
        call = function() end,
    }
end

