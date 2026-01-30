-- script/factory-logic.lua

local get_factory_by_building = remote_api.get_factory_by_building
local find_surrounding_factory = remote_api.find_surrounding_factory
local has_layout = has_layout

-- СИСТЕМА ДВЕРЕЙ (НОВОЕ) --

local function create_factory_door(factory, building)
    -- Если дверь уже существует (например, при перестроении), удаляем её
    if factory.entrance_door and factory.entrance_door.valid then
        storage.factories_by_entity[factory.entrance_door.unit_number] = nil
        factory.entrance_door.destroy()
    end

    -- Рассчитываем позицию: x по центру, y на нижнем краю здания
    local offset_y = (building.prototype.tile_height / 2) - 0.3
    local spawn_pos = {
        building.position.x,
        building.position.y + offset_y
    }
    
    local door = building.surface.create_entity{
        name = "factory-entrance-door",
        position = spawn_pos,
        force = building.force
    }
    
    if door then
        door.destructible = false
        door.operable = false
        -- Привязываем дверь к объекту фабрики для скрипта travel.lua
        storage.factories_by_entity[door.unit_number] = factory
        factory.entrance_door = door
    end
end

-- INITIALIZATION --

local dynamic_surface_factories = {
    "space-platform-hub-building-tier-1",
    "space-platform-hub-building-tier-2",
}

factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.factories = storage.factories or {}
    storage.saved_factories = storage.saved_factories or {}
    storage.factories_by_entity = storage.factories_by_entity or {}
    storage.surface_factories = storage.surface_factories or {}
    storage.next_factory_surface = storage.next_factory_surface or 0
    storage.was_deleted = storage.was_deleted or {}
end)

-- Вспомогательные функции для Space Age --

local function true_name(surface)
    if surface.name:find("%-factory%-floor$") then
        return surface.name:gsub("%-factory%-floor$", "")
    elseif (surface.object_name or type(surface)) == "LuaSurface" then
        if surface.planet or surface.platform then
            return (surface.planet and surface.planet.name) or (surface.platform and surface.platform.name)
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
        local original_planet = factory.original_planet
        local inside_surface = factory.inside_surface

        if original_planet and original_planet.valid then
            if inside_surface and inside_surface.valid then
                local original_planet_name = true_name(original_planet)
                local surface_name = true_name(surface)
                if original_planet_name ~= surface_name then
                    return false, {"factory-connection-text.invalid-placement-planet", original_planet_name}, true
                end
            end
        end

        if settings.global["Factorissimo2-free-recursion"].value then return true end

        local surrounding_factory = find_surrounding_factory(surface, position)
        if not surrounding_factory then return true end

        local has_tech_t2 = surrounding_factory.force.technologies["factory-recursion-t2"].researched
        local has_tech_t1 = has_tech_t2 or surrounding_factory.force.technologies["factory-recursion-t1"].researched

        if not has_tech_t2 and factory.layout.tier >= surrounding_factory.layout.tier then
            return false, {"factory-connection-text.invalid-placement-recursion-2"}, false
        end
        if not has_tech_t1 then
            return false, {"factory-connection-text.invalid-placement-recursion-1"}, false
        end

        return true
    end

    local can_place, msg, cancel_creation = can_place_factory_here()
    factory.inactive = not can_place
    
    if not can_place and msg then
        factorissimo.create_flying_text {position = position, text = msg}
    end
end

-- FACTORY GENERATION --

local function which_void_surface_should_this_new_factory_be_placed_on(layout, building)
    if layout.surface_override then return layout.surface_override end
    local surface = building.surface
    
    -- Логика для платформ и планет Space Age
    if surface.platform then
        return (surface.platform.index .. "-factory-floor")
    end
    
    if surface.planet then
        return (surface.planet.name .. "-factory-floor")
    end

    storage.next_factory_surface = storage.next_factory_surface + 1
    return storage.next_factory_surface .. "-factory-floor"
end

local function create_factory_position(layout, building)
    local surface_name = which_void_surface_should_this_new_factory_be_placed_on(layout, building)
    local surface = game.get_surface(surface_name)

    if not surface then
        local planet = game.planets[surface_name]
        if planet then
            surface = planet.surface or planet.create_surface()
        else
            surface = game.create_surface(surface_name, {width = 2, height = 2})
        end
        surface.daytime = 0.5
        surface.freeze_daytime = true
    end

    local n = #storage.surface_factories[surface.index] or 0
    local spacing = 16
    local cx, cy = spacing * (n % 8), spacing * math.floor(n / 8)

    local factory = {
        inside_surface = surface,
        inside_x = 32 * cx,
        inside_y = 32 * cy,
        stored_pollution = 0,
        outside_x = building.position.x,
        outside_y = building.position.y,
        outside_surface = building.surface
    }

    storage.surface_factories[surface.index] = storage.surface_factories[surface.index] or {}
    storage.surface_factories[surface.index][n + 1] = factory
    
    factory.id = #storage.factories + 1
    storage.factories[factory.id] = factory

    return factory
end

function create_factory_interior(layout, building)
    local factory = create_factory_position(layout, building)
    factory.building = building
    factory.layout = layout
    factory.force = building.force
    factory.quality = building.quality
    factory.inside_door_x = layout.inside_door_x + factory.inside_x
    factory.inside_door_y = layout.inside_door_y + factory.inside_y

    -- Генерация пола
    local tiles = {}
    for _, rect in pairs(layout.rectangles) do
        for x = rect.x1, rect.x2 - 1 do
            for y = rect.y1, rect.y2 - 1 do
                table.insert(tiles, {name = rect.tile, position = {factory.inside_x + x, factory.inside_y + y}})
            end
        end
    end
    factory.inside_surface.set_tiles(tiles)

    return factory
end

function create_factory_exterior(factory, building)
    factory.outside_x = building.position.x
    factory.outside_y = building.position.y
    factory.outside_surface = building.surface
    
    -- Энергоприемник
    local oer = building.surface.create_entity {
        name = factory.layout.outside_energy_receiver_type, 
        position = building.position, 
        force = building.force
    }
    if oer then
        oer.destructible = false
        oer.operable = false
        factory.outside_energy_receiver = oer
    end

    -- СОЗДАНИЕ ДВЕРИ (НОВОЕ)
    create_factory_door(factory, building)

    storage.factories_by_entity[building.unit_number] = factory
    factory.building = building
    factory.built = true

    return factory
end

-- CLEANUP --

function cleanup_factory_exterior(factory, building)
    -- Удаление двери (НОВОЕ)
    if factory.entrance_door and factory.entrance_door.valid then
        storage.factories_by_entity[factory.entrance_door.unit_number] = nil
        factory.entrance_door.destroy()
        factory.entrance_door = nil
    end

    if factory.outside_energy_receiver and factory.outside_energy_receiver.valid then
        factory.outside_energy_receiver.destroy()
    end
    
    factory.building = nil
    factory.built = false
end

-- EVENTS --

local function handle_factory_placed(entity, tags)
    local factory
    if tags and tags.id then
        factory = storage.saved_factories[tags.id]
        storage.saved_factories[tags.id] = nil
    end

    if factory and factory.inside_surface and factory.inside_surface.valid then
        factory.quality = entity.quality
        create_factory_exterior(factory, entity)
    else
        local layout = remote_api.create_layout(entity.name, entity.quality)
        factory = create_factory_interior(layout, entity)
        create_factory_exterior(factory, entity)
        factory.original_planet = entity.surface.planet
    end
    set_factory_active_or_inactive(factory)
end

factorissimo.on_event({defines.events.on_built_entity, defines.events.on_robot_built_entity}, function(event)
    local entity = event.entity
    if not (entity and entity.valid) then return end
    if has_layout(entity.name) then
        handle_factory_placed(entity, event.tags)
    end
end)

factorissimo.on_event({defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity}, function(event)
    local entity = event.entity
    if not has_layout(entity.name) then return end

    local factory = storage.factories_by_entity[entity.unit_number]
    if not factory then return end

    cleanup_factory_exterior(factory, entity)
    storage.saved_factories[factory.id] = factory
    
    -- Возвращаем предмет с ID фабрики в тегах
    if event.buffer then
        event.buffer.clear()
        event.buffer.insert{name = entity.name .. "-instantiated", count = 1, tags = {id = factory.id}}
    end
end)

return {
    create_factory_door = create_factory_door,
    cleanup_factory_exterior = cleanup_factory_exterior
}