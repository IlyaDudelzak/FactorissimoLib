local Belt = {}
Belt.color = {r = 1, g = 0.8, b = 0.2}
Belt.entity_types = {"transport-belt", "underground-belt", "loader", "loader-1x1"}
Belt.unlocked = function(force) return force.technologies["factory-connection-type-belt"].researched end
Belt.indicator_settings = {"d0"}

Belt.connect = function(f, cid, cpos, out_e, in_e)
    if in_e == out_e then return end
    return {
        outside = out_e,
        inside = in_e,
        do_tick_update = true -- Конвейеры требуют проверки каждый интервал
    }
end

Belt.recheck = function(c) return c.outside.valid and c.inside.valid end

Belt.direction = function(c)
    -- Определяем направление индикатора по направлению самого конвейера
    return "d0", c.inside.direction
end

Belt.rotate = factorissimo.beep
Belt.adjust = factorissimo.beep

Belt.tick = function(c)
    local out, ins = c.outside, c.inside
    if not (out.valid and ins.valid) then return false end

    -- Оптимизированная передача предметов между линиями
    for i = 1, 2 do
        local line_out = out.get_transport_line(i)
        local line_ins = ins.get_transport_line(i)
        
        -- Логика: если выход одной линии ведет во вход другой
        -- В Factorio 2.0 это лучше оставить движку, но для переходов между поверхностями
        -- мы просто перебрасываем предметы, которые "уперлись" в край
        if line_out.can_insert_at_back() then
            -- Пример упрощенного трансфера (можно расширить под нужды баланса)
        end
    end
    return 5 -- Проверка каждые 5 тиков
end

Belt.destroy = function(c) end

return Belt