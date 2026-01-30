local Heat = {}

Heat.color = {r = 228 / 255, g = 236 / 255, b = 0}
Heat.entity_types = {"heat-pipe"}

-- Проверка технологии (убедись, что имя совпадает с твоим в data.lua)
Heat.unlocked = function(force) 
    return force.technologies["factory-connection-type-heat"] and force.technologies["factory-connection-type-heat"].researched 
end

Heat.connect = function(factory, cid, cpos, outside_entity, inside_entity)
    -- Используем координаты из cpos (подключения фабрики)
    local inside_link = inside_entity.surface.create_entity {
        name = "factory-heat-dummy-connector",
        position = {factory.inside_x + cpos.inside_x + cpos.indicator_dx, factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        create_build_effect_smoke = false,
        raise_built = false,
        force = inside_entity.force
    }
    if inside_link then
        inside_link.destructible = false
        inside_link.active = false
    end

    local outside_link = outside_entity.surface.create_entity {
        name = "factory-heat-dummy-connector",
        position = {outside_entity.position.x - cpos.indicator_dx, outside_entity.position.y - cpos.indicator_dy},
        create_build_effect_smoke = false,
        raise_built = false,
        force = outside_entity.force
    }
    if outside_link then
        outside_link.destructible = false
        outside_link.active = false
    end

    return {
        outside = outside_entity,
        outside_link = outside_link,
        inside_link = inside_link,
        inside = inside_entity,
        do_tick_update = true,
        _settings = {} -- Инициализируем настройки, чтобы не было nil-ошибок
    }
end

Heat.recheck = function(conn)
    return conn.outside and conn.outside.valid and conn.inside and conn.inside.valid 
           and conn.inside_link and conn.inside_link.valid and conn.outside_link and conn.outside_link.valid
end

local DELAYS = {5, 10, 30, 120}
local DEFAULT_DELAY = 30

Heat.indicator_settings = {"d0", "b0"}
for _, v in pairs(DELAYS) do
    table.insert(Heat.indicator_settings, "b" .. v)
end

local function make_valid_delay(delay)
    for _, v in pairs(DELAYS) do
        if v == delay then return v end
    end
    return 0
end

Heat.direction = function(conn)
    local delay = (conn._settings and conn._settings.delay) or DEFAULT_DELAY
    return "b" .. make_valid_delay(delay), defines.direction.north
end

-- Безопасный вызов звука
Heat.rotate = function(player)
    if factorissimo.beep then factorissimo.beep(player) end
end

Heat.adjust = function(conn, positive)
    conn._settings = conn._settings or {}
    local delay = conn._settings.delay or DEFAULT_DELAY
    if positive then
        for i = #DELAYS, 1, -1 do
            if DELAYS[i] < delay then
                delay = DELAYS[i]
                break
            end
        end
        conn._settings.delay = delay
        return {"factory-connection-text.update-faster", delay}
    else
        for i = 1, #DELAYS do
            if DELAYS[i] > delay then
                delay = DELAYS[i]
                break
            end
        end
        conn._settings.delay = delay
        return {"factory-connection-text.update-slower", delay}
    end
end

-- Логика передачи тепла
Heat.tick = function(conn)
    local outside = conn.outside
    local inside = conn.inside
    if not (outside and outside.valid and inside and inside.valid) then return false end

    local temp_1, temp_2 = outside.temperature, inside.temperature
    if temp_1 == temp_2 then return conn._settings.delay or DEFAULT_DELAY end

    local average_temp = (temp_1 + temp_2) / 2
    
    -- Получаем прототипы буферов (важно в 2.0)
    local out_buffer = outside.prototype.heat_buffer_prototype
    local in_buffer = inside.prototype.heat_buffer_prototype
    
    if not (out_buffer and in_buffer) then return conn._settings.delay or DEFAULT_DELAY end

    local max_temp_1 = out_buffer.max_temperature
    local max_temp_2 = in_buffer.max_temperature

    -- Передаем энергию, учитывая лимиты
    if max_temp_1 < average_temp then
        outside.temperature = max_temp_1
        inside.temperature = temp_2 - (max_temp_1 - temp_1)
    elseif max_temp_2 < average_temp then
        inside.temperature = max_temp_2
        outside.temperature = temp_1 - (max_temp_2 - temp_2)
    else
        outside.temperature = average_temp
        inside.temperature = average_temp
    end

    return conn._settings.delay or DEFAULT_DELAY
end

Heat.destroy = function(conn)
    if conn.outside_link and conn.outside_link.valid then conn.outside_link.destroy() end
    if conn.inside_link and conn.inside_link.valid then conn.inside_link.destroy() end
end

return Heat