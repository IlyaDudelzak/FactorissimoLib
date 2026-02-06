if not script then
    script = {active_mods = {}}
end

local find_surrounding_factory = remote_api.find_surrounding_factory
local find_factory_by_area = remote_api.find_factory_by_area

local god_controllers = {
    [defines.controllers.god] = true,
    [defines.controllers.editor] = true,
    [defines.controllers.spectator] = true,
    [defines.controllers.remote] = true,
}

factorissimo.on_event(factorissimo.events.on_init(), function()
    factorissimo.log("LOG: Initializing travel module")
    storage.last_player_teleport = storage.last_player_teleport or {}
end)

local function get_purgatory_surface()
    factorissimo.log("LOG: Getting purgatory surface")
    if remote.interfaces["RSO"] then
        pcall(remote.call, "RSO", "ignoreSurface", "factory-travel-surface")
    end

    local planet = game.planets["factory-travel-surface"]
    if planet and planet.surface then return planet.surface end

    local surface = planet.create_surface()
    factorissimo.log("LOG: Created new purgatory surface")
    surface.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
    return surface
end

local function teleport_safely(entity, surface, position, player)
    factorissimo.log("LOG: Teleporting entity safely")
    local pos = {x = position.x or position[1], y = position.y or position[2]}

    if entity.is_player() and not entity.character then
        factorissimo.log("LOG: Teleporting player without character")
        entity.teleport(pos, surface)
    else
        factorissimo.log("LOG: Teleporting character")
        local safe_pos = surface.find_non_colliding_position(
            entity.character.name, pos, 5, 0.5, false
        ) or pos
        entity.teleport({0, 0}, get_purgatory_surface())
        entity.teleport(safe_pos, surface)
    end

    if player then
        storage.last_player_teleport[player.index] = game.tick
        factorissimo.update_factory_preview(player)
    end
end

local function enter_factory(entity, factory, player)
    factorissimo.log("LOG: Entering factory")
    teleport_safely(entity, factory.inside_surface, {factory.inside_door_x, factory.inside_door_y}, player)
end

local function leave_factory(entity, factory, player)
    factorissimo.log("LOG: Leaving factory")
    teleport_safely(entity, factory.outside_surface, {factory.outside_door_x, factory.outside_door_y}, player)
end

-- Define the serpent global for logging purposes
if not serpent then
    serpent = {}
    function serpent.line(value)
        return tostring(value)
    end
end

-- Correct the remote.call usage in get_jetpack_data
local function get_jetpack_data()
    factorissimo.log("LOG: Getting jetpack data")
    if script.active_mods["jetpack"] then
        local success, result = pcall(function()
            return remote.call("jetpack", "get_jetpacks") -- Ensure no extra arguments are passed
        end)
        if success then
            return result
        else
            factorissimo.log("LOG: Failed to call remote API for jetpack data")
            return nil
        end
    end
    return nil
end

local function is_player_airborne(jetpacks, player)
    -- factorissimo.log("LOG: Checking if player is airborne")
    if not player.character then return false end

    local armor_inv = player.get_inventory(defines.inventory.character_armor)
    if armor_inv and not armor_inv.is_empty() then
        local armor = armor_inv[1]
        if armor.valid_for_read and armor.prototype.provides_flight then
            return true
        end
    end

    if jetpacks then
        local data = jetpacks[player.character.unit_number]
        return data and data.status == "flying"
    end
    return false
end

local function check_and_leave_factory(player, airborne)
    -- factorissimo.log("LOG: Checking and leaving factory")
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

    local exit_threshold = factory.inside_door_y + (airborne and 0.5 or -1)
    if pos.y <= exit_threshold then return end

    if math.abs(pos.x - factory.inside_door_x) >= 4 then return end

    leave_factory(player, factory, player)
    factorissimo.update_overlay(factory)
    return true
end

local function check_and_enter_factory(player, airborne)
    local surface = player.physical_surface
    local pos = player.physical_position

    local doors = surface.find_entities_filtered{
        area = {{pos.x - 1, pos.y - 1}, {pos.x + 1, pos.y + 1}},
        type = "simple-entity-with-force"
    }
    -- game.print("LOG: doors found near player: " .. serpent.line(doors))
    local door = nil
    for _, d in pairs(doors) do
        if d.name:find("factory%-entrance%-door") then
            door = d
            break
        end
    end

    if door then
        -- factorissimo.log("LOG: Found door near player for entering factory")
        local factory = remote_api.get_factory_by_entity(door)
        if factory and not factory.inactive then
            local layout = factory.layout
            local side = layout.door.side
            local dir = player.walking_state.direction

            local can_enter = false

            if airborne then
                can_enter = true
            elseif side == "s" and (dir == defines.direction.north or dir == defines.direction.northeast or dir == defines.direction.northwest) then
                can_enter = true
            elseif side == "n" and (dir == defines.direction.south or dir == defines.direction.southeast or dir == defines.direction.southwest) then
                can_enter = true
            elseif side == "e" and (dir == defines.direction.west or dir == defines.direction.northwest or dir == defines.direction.southwest) then
                can_enter = true
            elseif side == "w" and (dir == defines.direction.east or dir == defines.direction.northeast or dir == defines.direction.southeast) then
                can_enter = true
            end

            if can_enter then
                teleport_safely(player, factory.inside_surface, {factory.inside_door_x, factory.inside_door_y}, player)
                return true
            end
        end
    else
        -- factorissimo.log("LOG: No door found near player for entering factory")
    end
    return false
end

script.on_nth_tick(2, function()
    -- factorissimo.log("LOG: Checking player movements on nth tick")
    local tick = game.tick
    local jetpacks = get_jetpack_data()

    for _, player in pairs(game.connected_players) do
        if player.driving then goto continue end

        local last_tp = storage.last_player_teleport[player.index] or 0
        if tick - last_tp < 30 then goto continue end
        
        local is_walking = player.walking_state.active -- Игрок жмет клавишу движения
        local airborne = is_player_airborne(jetpacks, player)

        if not is_walking and not airborne then 
            goto continue 
        end
        
        if not check_and_enter_factory(player, airborne) then
            check_and_leave_factory(player, airborne)
        end

        ::continue::
    end
    -- factorissimo.log("LOG: Finished checking player movements on nth tick")
end)

factorissimo.on_event(defines.events.on_player_changed_surface, function(e)
    factorissimo.log("LOG: Player changed surface")
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