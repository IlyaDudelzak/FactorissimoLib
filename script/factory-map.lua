local FactoryMap = {}

-- Поиск свободной позиции на поверхности пола (сетка 8x8 чанков)
function FactoryMap.findFirstUnusedPosition(surface)
    local usedIndexes = {}
    for k in pairs(storage.surfaceFactories[surface.index] or {}) do
        table.insert(usedIndexes, k)
    end
    table.sort(usedIndexes)

    for i, index in ipairs(usedIndexes) do
        if i ~= index then return (usedIndexes[i - 1] or 0) + 1 end
    end
    return #usedIndexes + 1
end

-- Создание интерьера (плитка, стены)
function FactoryMap.createFactoryInterior(layout, building)
    local factory = factorissimo.createFactoryPosition(layout, building)
    factory.building = building
    factory.layout = layout
    factory.force = building.force
    factory.quality = building.quality
    
    local surface = factory.inside_surface
    local tiles = {}
    local offX, offY = factory.inside_x, factory.inside_y

    -- Отрисовка прямоугольников пола из layout
    for _, rect in pairs(layout.rectangles) do
        for x = rect.x1, rect.x2 - 1 do
            for y = rect.y1, rect.y2 - 1 do
                table.insert(tiles, {name = rect.tile, position = {offX + x, offY + y}})
            end
        end
    end

    surface.set_tiles(tiles)
    
    -- Создание радара для обзора внутри
    local radar = surface.create_entity {
        name = "factorissimo-factory-radar",
        position = {offX, offY},
        force = factory.force,
    }
    radar.destructible = false
    factory.radar = radar

    return factory
end

-- Настройка свойств поверхности (гравитация, давление для 2.0)
function FactoryMap.setupSurfaceProperties(surface, isSpace)
    if isSpace then
        surface.set_property("gravity", 0)
        surface.set_property("pressure", 0)
        surface.set_property("magnetic-field", 0)
    end
    surface.daytime = 0.5
    surface.freeze_daytime = true
end

return FactoryMap