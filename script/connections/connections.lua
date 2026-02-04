local find_surrounding_factory = remote_api.find_surrounding_factory
local type_map = {}
local c_logic = {} -- Объединяем все таблицы классов в одну для удобства
local connection_indicator_names = {}
factorissimo.connection_indicator_names = connection_indicator_names

local function register_connection_type(ctype, class)
    for _, etype in pairs(class.entity_types) do type_map[etype] = ctype end
    c_logic[ctype] = class
    for _, name in pairs(class.indicator_settings) do
        connection_indicator_names["factory-connection-indicator-" .. ctype .. "-" .. name] = ctype
    end
end

local function is_connectable(entity)
    return type_map[entity.type] or type_map[entity.name]
end
factorissimo.is_connectable = is_connectable

-- Data Structure
local CYCLIC_BUFFER_SIZE = 600
factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.connections = storage.connections or {}
    storage.delayed_connection_checks = storage.delayed_connection_checks or {}
    for i = 0, CYCLIC_BUFFER_SIZE - 1 do storage.connections[i] = storage.connections[i] or {} end

    for _, factory in pairs(storage.factories) do
        if factory.built then factorissimo.recheck_factory_connections(factory) end
    end
end)

local function add_to_queue(conn)
    local pos = (math.floor(game.tick / CONNECTION_UPDATE_RATE) + 1) * CONNECTION_UPDATE_RATE % CYCLIC_BUFFER_SIZE
    table.insert(storage.connections[pos], conn)
end

-- Indicators
local function update_indicator(factory, cid, ctype, conn)
    if factory.connection_indicators[cid] then factory.connection_indicators[cid].destroy() end
    local setting, dir = c_logic[ctype].direction(conn)
    local cpos = factory.layout.connections[cid]
    factory.connection_indicators[cid] = factory.inside_surface.create_entity {
        name = "factory-connection-indicator-" .. ctype .. "-" .. setting,
        force = factory.force,
        position = {factory.inside_x + cpos.inside_x + cpos.indicator_dx, factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        direction = dir,
        quality = factory.quality
    }
end

-- Connection Management
local function register_connection(factory, cid, ctype, conn, settings)
    conn._id, conn._type, conn._factory, conn._settings, conn._valid = cid, ctype, factory, settings, true
    factory.connections[cid] = conn
    if conn.do_tick_update then add_to_queue(conn) end
    update_indicator(factory, cid, ctype, conn)
end

function factorissimo.destroy_connection(conn)
    if conn and conn._valid then
        c_logic[conn._type].destroy(conn)
        conn._valid = false
        conn._factory.connections[conn._id] = nil
        if conn._factory.connection_indicators[conn._id] then conn._factory.connection_indicators[conn._id].destroy() end
    end
end

local function init_connection(factory, cid, cpos)
    if factory.inactive or not (factory.outside_surface.valid and factory.inside_surface.valid) then return end

    local function get_ents(surf, x, y) 
        return surf.find_entities_filtered{position = {x, y}, force = factory.force} 
    end

    local outs = get_ents(factory.outside_surface, cpos.outside_x + factory.outside_x, cpos.outside_y + factory.outside_y)
    local ins = get_ents(factory.inside_surface, cpos.inside_x + factory.inside_x, cpos.inside_y + factory.inside_y)

    if #outs == 0 or #ins == 0 then return end

    for _, out_e in pairs(outs) do
        local ctype = type_map[out_e.type] or type_map[out_e.name]
        if not ctype then goto skip_out end

        for _, in_e in pairs(ins) do
            if ctype == (type_map[in_e.type] or type_map[in_e.name]) then
                if not c_logic[ctype].unlocked(factory.force) then
                    factorissimo.create_flying_text{position = in_e.position, text = {"research-required"}}
                    goto skip_in
                end

                local settings = factory.connection_settings[cid] or {}
                factory.connection_settings[cid] = settings
                settings[ctype] = settings[ctype] or {}
                
                local conn = c_logic[ctype].connect(factory, cid, cpos, out_e, in_e, settings[ctype])
                if conn then
                    local s = "entity-close/assembling-machine-3"
                    factory.inside_surface.play_sound{path = s, position = in_e.position}
                    register_connection(factory, cid, ctype, conn, settings[ctype])
                    return
                end
            end
            ::skip_in::
        end
        ::skip_out::
    end
end

-- Optimization: Simplified AABB
local function aabb_collision(p, box, target)
    return not (p.x + box.right_bottom.x < target.left_top.x or target.right_bottom.x < p.x + box.left_top.x or
                p.y + box.right_bottom.y < target.left_top.y or target.right_bottom.y < p.y + box.left_top.y)
end

local function recheck_nearby_connections(entity, delayed)
    local pos, surf, proto = entity.position, entity.surface, entity.prototype
    local box = table.deepcopy(proto.collision_box)
    local orient = entity.orientation or 0 -- Исправлено: берем ориентацию сущности

    if orient == 0.5 then box.left_top.y, box.right_bottom.y = -box.right_bottom.y, -box.left_top.y
    elseif orient == 0.25 or orient == 0.75 then
        box.left_top.x, box.left_top.y, box.right_bottom.x, box.right_bottom.y = -box.right_bottom.y, -box.right_bottom.x, -box.left_top.y, -box.left_top.x
    end

    local area = {
        left_top = {x = pos.x + math.floor(box.left_top.x) - 0.3, y = pos.y + math.floor(box.left_top.y) - 0.3},
        right_bottom = {x = pos.x + math.ceil(box.right_bottom.x) + 0.3, y = pos.y + math.ceil(box.right_bottom.y) + 0.3}
    }

    for _, f in pairs(storage.factories) do
        if f.built and f.outside_surface == surf and f.building.valid and aabb_collision(f.building.position, f.building.prototype.collision_box, area) then
            if delayed then table.insert(storage.delayed_connection_checks, {factory = f, outside_area = area})
            else factorissimo.recheck_factory_connections(f, area) end
            break
        end
    end

    local f_inside = find_surrounding_factory(surf, pos)
    if f_inside then
        if delayed then table.insert(storage.delayed_connection_checks, {factory = f_inside, inside_area = area})
        else factorissimo.recheck_factory_connections(f_inside, nil, area) end
    end
end

-- Tick Handler
CONNECTION_UPDATE_RATE = 5
factorissimo.on_nth_tick(CONNECTION_UPDATE_RATE, function()
    for _, check in pairs(storage.delayed_connection_checks) do
        factorissimo.recheck_factory_connections(check.factory, check.outside_area, check.inside_area)
    end
    storage.delayed_connection_checks = {}

    local pos = game.tick % CYCLIC_BUFFER_SIZE
    local slot = storage.connections[pos]
    storage.connections[pos] = {}
    for _, conn in pairs(slot) do
        if conn._valid then
            local delay = c_logic[conn._type].tick(conn)
            if delay then
                local next_pos = (pos + delay) % CYCLIC_BUFFER_SIZE
                table.insert(storage.connections[next_pos], conn)
            else
                factorissimo.destroy_connection(conn)
                init_connection(conn._factory, conn._id, conn._factory.layout.connections[conn._id])
            end
        end
    end
end)

-- Events & Types Registry
register_connection_type("belt", require("belt"))
register_connection_type("chest", require("chest"))
register_connection_type("fluid", require("fluid"))
register_connection_type("circuit", require("circuit"))
register_connection_type("heat", require("heat"))

-- Define missing global variables for connection logic
c_unlocked = c_unlocked or {}
c_color = c_color or {}
c_connect = c_connect or {}
c_recheck = c_recheck or {}
c_direction = c_direction or {}
c_rotate = c_rotate or {}
c_adjust = c_adjust or {}
c_tick = c_tick or {}
c_destroy = c_destroy or {}

-- Add missing functions and definitions

local get_connection_settings = function(factory, cid, ctype)
    factory.connection_settings[cid] = factory.connection_settings[cid] or {}
    factory.connection_settings[cid][ctype] = factory.connection_settings[cid][ctype] or {}
    return factory.connection_settings[cid][ctype]
end
factorissimo.get_connection_settings = get_connection_settings

local function set_connection_indicator(factory, cid, ctype, setting, dir)
    local old_indicator = factory.connection_indicators[cid]
    if old_indicator and old_indicator.valid then old_indicator.destroy() end
    local cpos = factory.layout.connections[cid]
    local new_indicator = factory.inside_surface.create_entity {
        name = "factory-connection-indicator-" .. ctype .. "-" .. setting,
        force = factory.force,
        position = {x = factory.inside_x + cpos.inside_x + cpos.indicator_dx, y = factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        create_build_effect_smoke = false,
        direction = dir,
        quality = factory.quality
    }
    new_indicator.destructible = false
    factory.connection_indicators[cid] = new_indicator
end

local function delete_connection_indicator(factory, cid, ctype)
    local old_indicator = factory.connection_indicators[cid]
    if old_indicator and old_indicator.valid then old_indicator.destroy() end
end

local function register_connection(factory, cid, ctype, conn, settings)
    conn._id = cid
    conn._type = ctype
    conn._factory = factory
    conn._settings = settings
    conn._valid = true
    factory.connections[cid] = conn
    if conn.do_tick_update then add_to_queue(conn) end
    local setting, dir = c_direction[ctype](conn)
    set_connection_indicator(factory, cid, ctype, setting, dir)
end

local function init_connection(factory, cid, cpos)
    if factory.inactive then return end
    if not factory.outside_surface.valid then return end
    if not factory.inside_surface.valid then return end

    local outside_entities = factory.outside_surface.find_entities_filtered {
        position = {cpos.outside_x + factory.outside_x, cpos.outside_y + factory.outside_y},
        force = factory.force
    }
    if outside_entities == nil or not outside_entities[1] then return end

    local inside_entities = factory.inside_surface.find_entities_filtered {
        position = {cpos.inside_x + factory.inside_x, cpos.inside_y + factory.inside_y},
        force = factory.force
    }
    if inside_entities == nil or not inside_entities[1] then return end

    for _, outside_entity in pairs(outside_entities) do
        local outside_connection_type = type_map[outside_entity.type] or type_map[outside_entity.name]
        if outside_connection_type == nil then
            goto continue
        end

        for _, inside_entity in pairs(inside_entities) do
            local inside_connection_type = type_map[inside_entity.type] or type_map[inside_entity.name]
            if outside_connection_type ~= inside_connection_type then
                goto continue_2
            end

            if not c_unlocked[outside_connection_type](factory.force) then
                factorissimo.create_flying_text {position = inside_entity.position, text = {"research-required"}}
                factorissimo.create_flying_text {position = outside_entity.position, text = {"research-required"}}
            end

            local settings = get_connection_settings(factory, cid, outside_connection_type)
            local new_connection = c_connect[outside_connection_type](factory, cid, cpos, outside_entity, inside_entity, settings)
            if new_connection then
                factory.inside_surface.play_sound {path = "entity-close/assembling-machine-3", position = inside_entity.position}
                factory.outside_surface.play_sound {path = "entity-close/assembling-machine-3", position = outside_entity.position}
                register_connection(factory, cid, outside_connection_type, new_connection, settings)
                return
            end
            ::continue_2::
        end
        ::continue::
    end
end
factorissimo.init_connection = init_connection

local function destroy_connection(conn)
    if conn and conn._valid then
        c_destroy[conn._type](conn)
        conn._valid = false
        conn._factory.connections[conn._id] = nil
        delete_connection_indicator(conn._factory, conn._id, conn._type)
    end
end
factorissimo.destroy_connection = destroy_connection

local function recheck_factory_connections(factory, outside_area, inside_area)
    if not factory.built then return end
    for cid, cpos in pairs(factory.layout.connections) do
        if outside_area and not in_area(cpos.outside_x + factory.outside_x, cpos.outside_y + factory.outside_y, outside_area) then
            goto continue
        end
        if inside_area and not in_area(cpos.inside_x + factory.inside_x, cpos.inside_y + factory.inside_y, inside_area) then
            goto continue
        end

        local conn = factory.connections[cid]
        if conn then
            if c_logic[conn._type].recheck(conn) then
                -- Connection is valid, no action needed
            else
                factorissimo.destroy_connection(conn)
                init_connection(factory, cid, cpos)
            end
        else
            init_connection(factory, cid, cpos)
        end

        ::continue::
    end
end

factorissimo.recheck_factory_connections = recheck_factory_connections

local function in_area(x, y, area)
    return x >= area.left_top.x and x <= area.right_bottom.x and y >= area.left_top.y and y <= area.right_bottom.y
end