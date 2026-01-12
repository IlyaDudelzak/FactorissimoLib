local FactoryManager = {}

-- 1. ХРАНИЛИЩЕ И ИНИЦИАЛИЗАЦИЯ
function FactoryManager.initStorage()
    storage.factories = storage.factories or {}
    storage.savedFactories = storage.savedFactories or {}
    storage.factoriesByEntity = storage.factoriesByEntity or {}
    storage.surfaceFactories = storage.surfaceFactories or {}
    storage.nextFactorySurface = storage.nextFactorySurface or 0
    storage.wasDeleted = storage.wasDeleted or {}
end

-- Вспомогательная функция поиска
function FactoryManager.getByBuilding(building)
    if not building or not building.valid then return nil end
    return storage.factoriesByEntity[building.unit_number] -- unit_number это свойство игры, его менять нельзя
end

-- 2. ЛОГИКА РАЗМЕЩЕНИЯ (PLACED)
function FactoryManager.handleFactoryPlaced(entity, tags)
    if not tags or not tags.id then
        return factorissimo.createFreshFactory(entity)
    end

    local factory = storage.savedFactories[tags.id]
    storage.savedFactories[tags.id] = nil

    if factory and factory.inside_surface and factory.inside_surface.valid then
        -- Распаковка существующей фабрики
        factory.quality = entity.quality
        factorissimo.createFactoryExterior(factory, entity)
        factorissimo.setFactoryActiveOrInactive(factory)
        factorissimo.handleFactoryControlXed(factory)
        return
    end

    -- Если чертеж (копирование)
    if not factory and storage.factories[tags.id] then
        local newFactory = factorissimo.createFreshFactory(entity)
        factorissimo.copyEntityGhosts(storage.factories[tags.id], newFactory)
        factorissimo.updateOverlay(newFactory)
        return
    end

    -- Если была удалена
    if storage.wasDeleted and storage.wasDeleted[tags.id] then
        factorissimo.createFreshFactory(entity)
        return
    end

    factorissimo.createFlyingText{position = entity.position, text = {"factory-connection-text.invalid-factory-data"}}
    entity.destroy()
end

-- 3. КЛОНИРОВАНИЕ (CLONING)
local cloneForbiddenPrefixes = {
    "factory-1-", "factory-2-", "factory-3-", "space-factory-1-",
    "factory-power-input-", "factory-connection-indicator-", "factory-power-pole",
    "factory-overlay-controller", "factory-port-marker", "factory-hidden-radar-"
}

function FactoryManager.isEntityCloneForbidden(name)
    for _, prefix in pairs(cloneForbiddenPrefixes) do
        if name:sub(1, #prefix) == prefix then return true end
    end
    return false
end

-- 4. ОБРАБОТКА СОБЫТИЙ (EVENTS)
function FactoryManager.registerEvents()
    
    -- Когда построили здание
    factorissimo.on_event(factorissimo.events.on_built(), function(event)
        local entity = event.entity
        if not entity.valid then return end
        
        if has_layout(entity.name) then
            local inventory = event.consumed_items
            local tags = event.tags or (inventory and not inventory.is_empty() and inventory[1].valid_for_read and inventory[1].is_item_with_tags and inventory[1].tags) or nil
            FactoryManager.handleFactoryPlaced(entity, tags)
        elseif entity.type == "entity-ghost" and has_layout(entity.ghost_name) and entity.tags then
            local copied = storage.factories[entity.tags.id]
            if copied then factorissimo.updateOverlay(copied, entity) end
        end
    end)

    -- Когда клонировали (через редактор или моды)
    factorissimo.on_event(defines.events.on_entity_cloned, function(event)
        local src = event.source
        local dst = event.destination
        if FactoryManager.isEntityCloneForbidden(dst.name) then
            dst.destroy()
        elseif has_layout(src.name) then
            local factory = FactoryManager.getByBuilding(src)
            if factory then
                factorissimo.cleanupFactoryExterior(factory, src)
                if src.valid then src.destroy() end
                factorissimo.createFactoryExterior(factory, dst)
                factorissimo.setFactoryActiveOrInactive(factory)
            end
        end
    end)
    
    -- Слияние сил (Force merge)
    factorissimo.on_event(defines.events.on_forces_merging, function(event)
        for _, factory in pairs(storage.factories) do
            if not factory.force.valid then factory.force = game.forces["player"] end
            if factory.force.name == event.source.name then factory.force = event.destination end
        end
    end)
end