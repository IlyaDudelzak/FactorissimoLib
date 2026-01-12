local function on_player_changed_surface(event)
    local player = game.get_player(event.player_index)
    if not player then
        log("Player with index " .. event.player_index .. " does not exist.")
        return
    end

    local old_surface = event.surface_index and game.surfaces[event.surface_index]
    local new_surface = player.surface

    log("Player " .. player.name .. " changed surfaces.")
    if old_surface then
        log("Old surface: " .. old_surface.name)
    else
        log("Old surface no longer exists.")
    end
    log("New surface: " .. new_surface.name)
end

local function on_entity_built(event)
    local entity = event.created_entity or event.entity
    if not entity then return end

    if is_space_platform_hub(entity) then
        log("Space platform hub built: " .. entity.name)
        game.print(entity.surface.platform.name)
    end
end

script.on_event(defines.events.on_player_changed_surface, on_player_changed_surface)
script.on_event(defines.events.on_built_entity, on_entity_built)

factorissimo.on_event(defines.events.on_built_entity, function(event)
    game.print("on_built_entity event triggered.")
end)

factorissimo.on_event(defines.events.on_robot_built_entity, function(event)
    game.print("on_robot_built_entity event triggered.")
end)

factorissimo.on_event(defines.events.script_raised_built, function(event)
    game.print("script_raised_built event triggered.")
end)

factorissimo.on_event(defines.events.on_space_platform_built_entity , function(event)
    game.print("on_space_platform_built_entity event triggered.")
end)

factorissimo.on_event(factorissimo.events.on_built(), function(event)
    game.print("factorissimo.events.on_built event triggered.")
end)

factorissimo.on_event(defines.events.on_surface_created, function(event)
    game.print("on_surface_created event triggered.")
    if(event.surface_index) then
        local surface = game.surfaces[event.surface_index]
        if surface then
            game.print("New surface created: " .. surface.name)
            if surface.platform then
                game.print("This surface is a space platform surface.")
                if(surface.platform.hub) then
                    game.print("Platform hub entity: " .. surface.platform.hub.name)
                else
                    game.print("No platform hub entity found.")
                end
            else
                game.print("This surface is NOT a space platform surface.")
            end
        end
    end
end)

local function init_space_platform(surface_name)
    local surface = game.surfaces[surface_name]
    
    if not surface or not surface.valid then return end

    local platform = surface.platform
    
    -- Мы уверены, что хаб уже должен был появиться
    if platform and platform.hub and platform.hub.valid then
        game.print("✅ УСПЕХ (Delayed): Хаб найден для платформы: " .. platform.name)
        
        local hub_entity = platform.hub
        
        -- >>> ВАШ КОД ИНИЦИАЛИЗАЦИИ ХАБА ЗДЕСЬ <<<
        
        hub_entity.insert({name="steel-plate", count=200})
        
    else
        game.print("❌ Ошибка (Delayed): Хаб не найден для платформы: " .. surface_name .. ". Возможно, нужно увеличить задержку.")
        -- Опционально: если хаба все еще нет, можно вызвать execute_later еще раз
    end
end

-- Регистрация функции, чтобы ее можно было вызвать по ключу
factorissimo.register_delayed_function('init_space_platform', init_space_platform)

factorissimo.on_event(defines.events.on_surface_created, function(event)
    local surface = game.surfaces[event.surface_index]
    
    if surface and surface.platform then
        game.print("New platform surface created: " .. surface.name .. ". Запускаем задержку...")
        
        -- Выполняем функцию init_space_platform через 10 тиков
        -- (10 тиков = ~0.16 секунды. Этого достаточно, чтобы игра успела создать хаб.)
        factorissimo.execute_later('init_space_platform', 10, surface.name)
    end
end)

factorissimo.on_event(defines.events.on_player_changed_surface, function(event)
    log("on_player_changed_surface event triggered.")
    local player = game.get_player(event.player_index)
    if not (player and player.valid) then
        log("Player is invalid or does not exist.")
        return
    end

    log("Player valid: " .. player.name)
    if player.surface.platform then
        log("Platform detected: " .. serpent.block(player.surface.platform))
        if player.surface.platform.hub then
            log("Platform hub detected: " .. serpent.block(player.surface.platform.hub))
            if player.surface.platform.hub.name == "space-platform-hub-building-tier-1" then
                log("Space platform hub matched: space-platform-hub-building-tier-1")
                player.print("You are on the space platform hub!")
            end
        else
            log("Platform hub is nil.")
        end
    else
        log("Platform is nil.")
    end
end)

factorissimo.on_event(factorissimo.events.on_space_platform_destroyed(), function(event)
    log("on_space_platform_destroyed event triggered.")
    if event.surface_index then
        local surface = game.surfaces[event.surface_index]
        if surface then
            log("Surface destroyed: " .. surface.name)
        else
            log("Surface with index " .. event.surface_index .. " does not exist.")
        end
    else
        log("Event does not contain surface_index.")
    end
end)