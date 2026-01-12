local Circuit = {}
Circuit.color = {r = 1, g = 0, b = 0}
Circuit.entity_types = {"constant-combinator"} -- Обычно используется как "порт"
Circuit.unlocked = function(force) return force.technologies["factory-connection-type-circuit"].researched end
Circuit.indicator_settings = {"d0"}

Circuit.connect = function(f, cid, cpos, out_e, in_e)
    -- Отключаем возможность ручной настройки, так как это системный порт
    out_e.operable = false
    in_e.operable = false
    return {
        outside = out_e,
        inside = in_e,
        do_tick_update = true
    }
end

Circuit.recheck = function(c) return c.outside.valid and c.inside.valid end

Circuit.direction = function(c) return "d0", 0 end
Circuit.rotate = factorissimo.beep
Circuit.adjust = factorissimo.beep

Circuit.tick = function(c)
    local out, ins = c.outside, c.inside
    if not (out.valid and ins.valid) then return false end

    -- Копирование сигналов (в 2.0 секции комбинаторов позволяют делать это гибко)
    local out_control = out.get_control_behavior()
    local ins_control = ins.get_control_behavior()
    
    -- Синхронизация секций (Sections) — новая фича 2.0
    local signals = out_control.get_section(1).filters
    ins_control.get_section(1).filters = signals

    return 5 -- Цепи должны работать быстро
end

Circuit.destroy = function(c) end

return Circuit