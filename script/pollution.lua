-- script/pollution.lua

local pollution_multipliers = {
    spores = 1.5,   -- Споры на Глебе распространяются активнее
    pollution = 1,  -- Обычное загрязнение
}

local function update_pollution(factory)
    local inside_surface = factory.inside_surface
    -- Проверка на валидность и наличие типа загрязнения
    if not (inside_surface and inside_surface.valid) then return end
    
    -- В 2.0 проверяем, может ли поверхность вообще принимать загрязнение
    -- Если поверхность не поддерживает поллютанты (например, орбита), выходим
    if not inside_surface.planet or not inside_surface.planet.prototype.pollutant then return end

    local pollution = 0
    local inside_x, inside_y = factory.inside_x, factory.inside_y

    -- Собираем загрязнение из 4 чанков внутри фабрики
    local chunks = {
        {inside_x - 16, inside_y - 16},
        {inside_x + 16, inside_y - 16},
        {inside_x - 16, inside_y + 16},
        {inside_x + 16, inside_y + 16}
    }

    for _, chunk in ipairs(chunks) do
        local cp = inside_surface.get_pollution(chunk)
        if cp ~= 0 then 
            inside_surface.pollute(chunk, -cp) -- Убираем загрязнение изнутри
            pollution = pollution + cp
        end
    end

    if pollution == 0 and (factory.stored_pollution or 0) <= 0 then return end

    local outside_surface = factory.outside_surface
    if factory.built and outside_surface and outside_surface.valid then
        -- Определяем тип поллютанта снаружи (на Наувисе - pollution, на Глебе - spores)
        local planet_proto = outside_surface.planet and outside_surface.planet.prototype
        local pollutant_type = planet_proto and planet_proto.pollutant and planet_proto.pollutant.name
        
        if not pollutant_type then 
            -- Если снаружи загрязнение не поддерживается, копим его внутри "хранилища"
            factory.stored_pollution = (factory.stored_pollution or 0) + pollution
            return 
        end

        local multiplier = pollution_multipliers[pollutant_type] or 1
        local pollution_to_release = (pollution + (factory.stored_pollution or 0)) * multiplier
        
        outside_surface.pollute({factory.outside_x, factory.outside_y}, pollution_to_release)
        factory.stored_pollution = 0
    else
        -- Если здание снесено или снаружи вакуум, копим в объекте фабрики
        factory.stored_pollution = (factory.stored_pollution or 0) + pollution
    end
end

-- Регистрация события (каждые 15 тиков, распределенно по группам)
-- factorissimo.on_nth_tick должен быть определен в control.lua
factorissimo.on_nth_tick(15, function(event)
    local factories = storage.factories
    if not factories then return end
    
    -- Распределяем нагрузку: в каждый тик обрабатываем только 1/4 всех фабрик
    for i = (event.tick % 4 + 1), #factories, 4 do
        local factory = factories[i]
        if factory ~= nil then update_pollution(factory) end
    end
end)

return {update_pollution = update_pollution}