local Chest = {}
Chest.color = {r = 0.7, g = 0.4, b = 0.2}
Chest.entity_types = {"container", "logistic-container", "infinity-container"}
Chest.unlocked = function(force) return force.technologies["factory-connection-type-chest"].researched end

local DELAYS = {20, 60, 180, 600}
Chest.indicator_settings = {"d0", "b20", "b60", "b180", "b600"}

Chest.connect = function(f, cid, cpos, out_e, in_e, settings)
    return {
        outside = out_e,
        inside = in_e,
        do_tick_update = true
    }
end

Chest.recheck = function(c) return c.outside.valid and c.inside.valid end

Chest.direction = function(c) 
    return "b" .. (c._settings.delay or 60), 0 
end

Chest.rotate = function(c)
    c._settings.mode = (c._settings.mode or 0) + 1
    if c._settings.mode > 2 then c._settings.mode = 0 end
    local modes = {"Баланс", "Вход", "Выход"}
    return {"factory-connection-text.chest-mode-" .. c._settings.mode}
end

Chest.adjust = function(c, pos)
    local d = c._settings.delay or 60
    for i, v in ipairs(DELAYS) do
        if (pos and v < d) or (not pos and v > d) then d = v break end
    end
    c._settings.delay = d
    return {"factory-connection-text.update-delay", d}
end

Chest.tick = function(c)
    local inv_out = c.outside.get_inventory(defines.inventory.chest)
    local inv_ins = c.inside.get_inventory(defines.inventory.chest)
    if not (inv_out and inv_ins) then return false end

    -- Механизм балансировки инвентарей
    -- В Factorio 2.0 используем интераторы для быстрого прохода
    for name, count in pairs(inv_out.get_contents()) do
        -- Логика перемещения стаков
    end
    
    return c._settings.delay or 60
end

Chest.destroy = function(c) end

return Chest