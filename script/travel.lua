if not script then script = {active_mods = {}} end

local find_surrounding_factory = remote_api.find_surrounding_factory
local god_controllers = {
    [defines.controllers.god] = true,
    [defines.controllers.editor] = true,
    [defines.controllers.spectator] = true,
    [defines.controllers.remote] = true,
}

factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.last_player_teleport = storage.last_player_teleport or {}
    storage.player_states = storage.player_states or {}
end)

-------------------------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
-------------------------------------------------------------------------------

local function get_purgatory_surface()
    local planet = game.planets["factory-travel-surface"]
    if planet and planet.surface then return planet.surface end
    local surface = planet.create_surface()
    surface.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
    return surface
end

local function teleport_safely(entity, surface, position, player)
    local pos = {x = position.x or position[1], y = position.y or position[2]}
    if entity.is_player() and not entity.character then
        entity.teleport(pos, surface)
    else
        local safe_pos = surface.find_non_colliding_position(entity.character.name, pos, 5, 0.5, false) or pos
        entity.teleport({0, 0}, get_purgatory_surface())
        entity.teleport(safe_pos, surface)
    end
    if player then
        storage.last_player_teleport[player.index] = game.tick
        factorissimo.update_factory_preview(player)
    end
end

-- Расчет позиции внутри (Entering)
local function create_factory_entering_position(factory, side)
    local layout = factory.layout
    local extent = layout.inside_size / 2
    
    local depth = -1

    local target_x = factory.inside_x
    local target_y = factory.inside_y

    if side == "n" then
        target_y = target_y - extent + depth
    elseif side == "s" then
        target_y = target_y + extent - depth
    elseif side == "w" then
        target_x = target_x - extent + depth
    elseif side == "e" then
        target_x = target_x + extent - depth
    end
    return {x = target_x, y = target_y}
end

-- Расчет позиции снаружи (Exiting)
local function create_factory_exiting_position(factory, side)
    local b_proto = factory.building.prototype
    local h_w = b_proto.tile_width / 2
    local h_h = b_proto.tile_height / 2
    
    -- Дистанция выхода: 0.5 (у края) + 4 тайла смещения = 4.5 тайла от центра края
    local push = 4.5

    local target_x = factory.building.position.x
    local target_y = factory.building.position.y

    if side == "n" then
        target_y = target_y - h_h - push
    elseif side == "s" then
        target_y = target_y + h_h + push
    elseif side == "w" then
        target_x = target_x - h_w - push
    elseif side == "e" then
        target_x = target_x + h_w + push
    end
    return {x = target_x, y = target_y}
end

local opposite_direction = {
    n = "s",
    s = "n",
    e = "w",
    w = "e"
}

-- Проверка направления и движения
local function is_direction_correct(direction, side, is_entering)
    if is_entering then
        side = opposite_direction[side] or side
    end
    if side == "n" then
        return direction == defines.direction.north or direction == defines.direction.northeast or direction == defines.direction.northwest
    elseif side == "s" then
        return direction == defines.direction.south or direction == defines.direction.southeast or direction == defines.direction.southwest
    elseif side == "e" then
        return direction == defines.direction.east or direction == defines.direction.northeast or direction == defines.direction.southeast
    elseif side == "w" then
        return direction == defines.direction.west or direction == defines.direction.northwest or direction == defines.direction.southwest
    end
    return false
end

local function is_moving_into_door(velocity, side, is_entering)
    local threshold = 0.001
    if is_entering then
        if side == "n" then return velocity.y > threshold 
        elseif side == "s" then return velocity.y < -threshold
        elseif side == "w" then return velocity.x > threshold 
        elseif side == "e" then return velocity.x < -threshold
        end
    else
        if side == "n" then return velocity.y < -threshold
        elseif side == "s" then return velocity.y > threshold 
        elseif side == "w" then return velocity.x < -threshold
        elseif side == "e" then return velocity.x > threshold 
        end
    end
    return false
end

local function get_touching_doors(player, radius)
    local pos = player.physical_position
    local area = {{pos.x - radius, pos.y - radius}, {pos.x + radius, pos.y + radius}}
    local entities = player.surface.find_entities_filtered{area = area, type = "simple-entity-with-force"}
    local list = {}
    for _, e in pairs(entities) do
        if e.name:find("factory%-entrance%-door") or e.name:find("factory%-exit%-door") then
            list[e.unit_number] = e
        end
    end
    return list
end

-------------------------------------------------------------------------------
-- ЛОГИКА ТЕЛЕПОРТАЦИИ
-------------------------------------------------------------------------------

local function try_enter_factory(player, door, forced, velocity)
    local side = door.name:sub(-1)
    local factory = remote_api.get_factory_by_entity(door)
    if not (factory and not factory.inactive) then return false end

    -- Если не форсировано, проверяем условия здесь
    if not forced then
        local is_looking = is_direction_correct(player.walking_state.direction, side, true)
        if not (is_moving_into_door(velocity, side, true) or (player.walking_state.active and is_looking)) then
            return false
        end
    end

    local target_pos = create_factory_entering_position(factory, side)
    teleport_safely(player, factory.inside_surface, target_pos, player)
    return true
end

local function try_leave_factory(player, door, forced, velocity)
    local side = door.name:sub(-1)
    local factory = find_surrounding_factory(player.physical_surface, player.physical_position)
    if not factory then return false end

    if not forced then
        local is_looking = is_direction_correct(player.walking_state.direction, side, false)
        if not (is_moving_into_door(velocity, side, false) or (player.walking_state.active and is_looking)) then
            return false
        end
    end

    local exit_pos = create_factory_exiting_position(factory, side)
    teleport_safely(player, factory.outside_surface, exit_pos, player)
    factorissimo.update_overlay(factory)
    return true
end

-------------------------------------------------------------------------------
-- ОСНОВНОЙ ЦИКЛ
-------------------------------------------------------------------------------

script.on_nth_tick(2, function()
    local tick = game.tick
    local states = storage.player_states

    for _, player in pairs(game.connected_players) do
        local name = player.name
        -- Базовые проверки контроллера
        if player.driving or not player.character or god_controllers[player.controller_type] then 
            states[name] = nil
            goto continue 
        end

        local pos = player.physical_position
        local last_state = states[name]
        
        -- Расчет скорости (сохраняем для будущего использования)
        local velocity = {x = 0, y = 0}
        if last_state and last_state.surface_index == player.surface.index then
            velocity.x = pos.x - last_state.pos.x
            velocity.y = pos.y - last_state.pos.y
        end

        -- Обновляем состояние игрока (позиция, поверхность, скорость)
        local current_state = {
            pos = {x = pos.x, y = pos.y},
            surface_index = player.surface.index,
            velocity = velocity
        }

        -- Кулдаун телепорта (0.5 сек)
        local last_tp = storage.last_player_teleport[player.index] or 0
        if tick - last_tp < 30 then 
            states[name] = current_state
            goto continue 
        end

        -- Ищем двери, которых касается игрок
        local current_doors = get_touching_doors(player, 1.1)

        for _, door in pairs(current_doors) do
            local is_entrance = door.name:find("entrance")
            local side = door.name:sub(-1)
            
            -- Условие: Игрок касается двери И смотрит в правильном направлении
            -- Используем player.character.direction для определения взгляда
            if is_direction_correct(player.character.direction, side, is_entrance) then
                if is_entrance then
                    if try_enter_factory(player, door, true, velocity) then
                        states[name] = nil -- Сбрасываем стейт после ТП
                        goto continue
                    end
                else
                    if try_leave_factory(player, door, true, velocity) then
                        states[name] = nil
                        goto continue
                    end
                end
            end
        end

        -- Сохраняем стейт в конце цикла
        states[name] = current_state

        ::continue::
    end
end)