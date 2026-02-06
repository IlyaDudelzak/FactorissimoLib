-- script/pollution.lua

local pollution_multipliers = {
    spores = 1.5,
    pollution = 1,
}

local function update_pollution(factory)
    local inside_surface = factory.inside_surface
    if not (inside_surface and inside_surface.valid) then return end

    if not inside_surface.planet or not inside_surface.planet.prototype.pollutant_type then return end

    local pollution = 0
    local inside_x, inside_y = factory.inside_x, factory.inside_y

    local chunks = {
        {inside_x - 16, inside_y - 16},
        {inside_x + 16, inside_y - 16},
        {inside_x - 16, inside_y + 16},
        {inside_x + 16, inside_y + 16}
    }

    for _, chunk in ipairs(chunks) do
        local cp = inside_surface.get_pollution(chunk)
        if cp ~= 0 then 
            inside_surface.pollute(chunk, -cp)
            pollution = pollution + cp
        end
    end

    if pollution == 0 and (factory.stored_pollution or 0) <= 0 then return end

    local outside_surface = factory.outside_surface
    if factory.built and outside_surface and outside_surface.valid then
        local planet_proto = outside_surface.planet and outside_surface.planet.prototype
        local pollutant_type = planet_proto and planet_proto.pollutant_type and planet_proto.pollutant_type.name

        if not pollutant_type then 
            factory.stored_pollution = (factory.stored_pollution or 0) + pollution
            return 
        end

        local multiplier = pollution_multipliers[pollutant_type] or 1
        local pollution_to_release = (pollution + (factory.stored_pollution or 0)) * multiplier

        outside_surface.pollute({factory.outside_x, factory.outside_y}, pollution_to_release)
        factory.stored_pollution = 0
    else
        factory.stored_pollution = (factory.stored_pollution or 0) + pollution
    end
end

factorissimo.on_nth_tick(15, function(event)
    local factories = storage.factories
    if not factories then return end

    for i = (event.tick % 4 + 1), #factories, 4 do
        local factory = factories[i]
        if factory ~= nil then update_pollution(factory) end
    end
end)

return {update_pollution = update_pollution}