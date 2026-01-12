local Lifecycle = {}
local Manager = require("script.factory-manager")

-- Проверка: можно ли сносить здание роботами-манипуляторами (модовыми)
function Lifecycle.preventFactoryMining(entity)
    local factory = Manager.getByBuilding(entity)
    if not factory then return end
    
    storage.factoriesByEntity[entity.unit_number] = nil
    local newBuilding = entity.surface.create_entity {
        name = entity.name,
        position = entity.position,
        force = entity.force,
        raise_built = false,
        create_build_effect_smoke = false,
        player = entity.last_user
    }
    storage.factoriesByEntity[newBuilding.unit_number] = factory
    factory.building = newBuilding
    factorissimo.updateOverlay(factory)
    
    factorissimo.createFlyingText {position = newBuilding.position, text = {"factory-cant-be-mined"}}
end

-- Обработка смерти здания (уничтожение кусаками)
function Lifecycle.handleEntityDied(event)
    local entity = event.entity
    if not has_layout(entity.name) then return end
    local factory = Manager.getByBuilding(entity)
    if not factory then return end

    storage.savedFactories[factory.id] = factory
    factorissimo.cleanupFactoryExterior(factory, entity)

    local items = entity.surface.spill_item_stack {
        position = entity.position,
        stack = {
            name = factory.layout.name .. "-instantiated",
            tags = {id = factory.id},
            quality = entity.quality.name,
            count = 1
        },
        enable_looted = false,
        max_radius = 0
    }
    
    if items[1] then
        factory.item = items[1].stack.item
        entity.force.print {"factory-killed-by-biters", items[1].gps_tag}
    end
end

return Lifecycle