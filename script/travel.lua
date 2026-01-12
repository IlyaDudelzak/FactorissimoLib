local find_surrounding_factory = remote_api.find_surrounding_factory
local find_factory_by_area = remote_api.find_factory_by_area

-- Контроллеры без физического тела (боги, редакторы и т.д.)
local god_controllers = {
    [defines.controllers.god] = true,
    [defines.controllers.editor] = true,
    [defines.controllers.spectator] = true,
    [defines.controllers.remote] = true,
}

factorissimo.on_event(factorissimo.events.on_init(), function()
    storage.last_player_teleport = storage.last_player_teleport or {}
end)

-- Создание технической поверхности для временного хранения игрока при телепортации
-- Это предотвращает баги с роботами и потерей инвентаря между поверхностями
local function get_purgatory_surface()
    if remote.interfaces["RSO"] then
        pcall(remote.call, "RSO", "ignoreSurface", "factory-travel-surface")
    end

    local planet = game.planets["factory-travel-surface"]
    if planet and planet.surface then return planet.surface end

    local surface = planet.create_surface()
    -- Генерируем минимальный чанк, чтобы было куда "приземлиться"
    surface.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
    return surface
end

-- Основная логика безопасного перемещения
local function teleport_safely(entity, surface, position, player)
    local pos = {x = position.x or position[1], y = position.y or position[2]}

    if entity.is_player() and not entity.character then
        -- Для игроков без персонажа (режим бога) просто прыгаем
        entity.teleport(pos, surface)
    else
        -- Для персонажей ищем свободное место рядом с дверью
        local safe_pos = surface.find_non_colliding_position(
            entity.character.name, pos, 5, 0.5, false
        ) or pos
        
        -- Двойной прыжок через "чистилище" фиксит баги с персональными робопортами
        entity.teleport({0, 0}, get_purgatory_surface())
        entity.teleport(safe_pos, surface)
    end

    if player then
        storage.last_player_teleport[player.index] = game.tick
        factorissimo.update_factory_preview(player)
    end
end

local function enter_factory(entity, factory, player)
    teleport_safely(entity, factory.inside_surface, {factory.inside_door_x, factory.inside_door_y}, player)
end

local function leave_factory(entity, factory, player)
    teleport_safely(entity, factory.outside_surface, {factory.outside_door_x, factory.outside_door_y}, player)
end

-- Совместимость с модом Jetpack
local function get_jetpack_data()
    if script.active_mods["jetpack"] then
        return remote.call("jetpack", "get_jetpacks", {})
    end
    return nil
end

local function is_player_airborne(jetpacks, player)
    if not player.character then return false end

    -- Проверка встроенных в броню реактивных двигателей (Space Age / Mech Suit)
    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv and not armor_inv.is_empty() then
        local armor = armor_inv[1]
        if armor.valid_for_read and armor.prototype.provides_flight then
            return true
        end
    end

    -- Проверка внешнего мода Jetpack
    if jetpacks then
        local data = jetpacks[player.character.unit_number]
        return data and data.status == "flying"
    end
    return false
end

-- Проверка выхода из фабрики (движение вниз через южную дверь)
local function check_and_leave_factory(player, airborne)
    if god_controllers[player.controller_type] then return end

    local walking_direction = player.walking_state.direction
    local is_moving_south = (
        walking_direction == defines.direction.south or
        walking_direction == defines.direction.southeast or
        walking_direction == defines.direction.southwest
    )

    if not is_moving_south then return end

    local pos = player.physical_position
    local factory = find_surrounding_factory(player.physical_surface, pos)
    if not factory then return end

    -- Порог по Y для выхода (чуть ниже двери)
    local exit_threshold = factory.inside_door_y + (airborne and 0.5 or -1)
    if pos.y <= exit_threshold then return end

    -- Проверка, что игрок по центру двери (коридор в 4 клетки)
    if math.abs(pos.x - factory.inside_door_x) >= 4 then return end

    leave_factory(player, factory, player)
    factorissimo.update_overlay(factory)
    return true
end

-- Проверка входа в здание (движение вверх через вход)
local function check_and_enter_factory(player, airborne)
    if player.controller_type == defines.controllers.remote then return end

    local walking_direction = player.walking_state.direction
    local is_moving_north = airborne or (
        walking_direction == defines.direction.north or
        walking_direction == defines.direction.northeast or
        walking_direction == defines.direction.northwest
    )

    if not is_moving_north then return end

    local pos = player.physical_position
    local factory = find_factory_by_area {
        surface = player.physical_surface,
        area = (not airborne) and {
            {pos.x - 0.2, pos.y - 0.3},
            {pos.x + 0.2, pos.y}
        } or nil,
        position = airborne and pos or nil
    }

    if not factory or factory.inactive then return end

    -- Дверь шире для тех, кто на джетпаке
    local door_width = airborne and 4 or 0.9
    local in_doorway = pos.y > factory.outside_y + 1 and math.abs(pos.x - factory.outside_x) < door_width
    
    if in_doorway then
        enter_factory(player, factory, player)
        return true
    end
end

-- Основной цикл проверки перемещений
factorissimo.on_nth_tick(6, function()
    local tick = game.tick
    local jetpacks = get_jetpack_data()
    
    for _, player in pairs(game.connected_players) do
        if player.driving then goto continue end
        
        -- Защита от спам-телепорта (Cooldown ~0.5 сек)
        local last_tp = storage.last_player_teleport[player.index] or 0
        if tick - last_tp < 30 then goto continue end
        
        if not player.walking_state.walking and not is_player_airborne(jetpacks, player) then 
            goto continue 
        end

        local airborne = is_player_airborne(jetpacks, player)
        if not check_and_enter_factory(player, airborne) then
            check_and_leave_factory(player, airborne)
        end

        ::continue::
    end
end)

-- Автоматический вход при смене поверхности (для Space Platform Hub)
factorissimo.on_event(defines.events.on_player_changed_surface, function(e)
    local player = game.get_player(e.player_index)
    if not player or god_controllers[player.controller_type] then return end
    
    local surface = player.surface
    if surface and surface.platform and surface.platform.hub then
        local factory = remote_api.get_factory_by_building(surface.platform.hub)
        if factory then
            enter_factory(player, factory, player)
        end
    end
end)