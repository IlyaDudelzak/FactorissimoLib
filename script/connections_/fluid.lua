local Fluid = {}
Fluid.color = {167/255, 229/255, 1}
Fluid.entity_types = {"pipe", "pipe-to-ground", "pump", "storage-tank", "infinity-pipe", "offshore-pump", "elevated-pipe"}
Fluid.unlocked = function(force) return force.technologies["factory-connection-type-fluid"].researched end
Fluid.indicator_settings = {"d0"}

local function create_links(factory, cpos, settings)
    local mode = settings.input_mode
    local ins_name = "factory-inside-pump-" .. (mode and "output" or "input")
    local outs_name = "factory-outside-pump-" .. (mode and "input" or "output")
    
    local ins = factory.inside_surface.create_entity{
        name = ins_name,
        position = {factory.inside_x + cpos.inside_x + cpos.indicator_dx, factory.inside_y + cpos.inside_y + cpos.indicator_dy},
        direction = cpos.direction_in,
        force = factory.force, quality = factory.quality
    }
    local outs = factory.outside_surface.create_entity{
        name = outs_name,
        position = {factory.outside_x + cpos.outside_x - cpos.indicator_dx, factory.outside_y + cpos.outside_y - cpos.indicator_dy},
        direction = cpos.direction_out,
        force = factory.force, quality = factory.quality
    }
    ins.destructible, ins.operable, outs.destructible, outs.operable = false, false, false, false
    ins.fluidbox.add_linked_connection(0, outs, 0)
    return ins, outs
end

Fluid.connect = function(f, cid, cpos, out_e, in_e, settings)
    if in_e == out_e then return end
    local ins, outs = create_links(f, cpos, settings)
    return {inside = in_e, outside = out_e, inside_connector = ins, outside_connector = outs, do_tick_update = false}
end

Fluid.recheck = function(c) return c.inside_connector.valid and c.outside_connector.valid and c.inside.valid and c.outside.valid end

Fluid.direction = function(c)
    local cpos = c._factory.layout.connections[c._id]
    return "d0", c._settings.input_mode and cpos.direction_in or cpos.direction_out
end

Fluid.rotate = function(c)
    c._settings.input_mode = not c._settings.input_mode
    if c.inside_connector.valid then c.inside_connector.destroy() end
    if c.outside_connector.valid then c.outside_connector.destroy() end
    c.inside_connector, c.outside_connector = create_links(c._factory, c._factory.layout.connections[c._id], c._settings)
    return {c._settings.input_mode and "factory-connection-text.input-mode" or "factory-connection-text.output-mode"}
end

Fluid.adjust = factorissimo.beep
Fluid.destroy = function(c)
    if c.outside_connector.valid then c.outside_connector.destroy() end
    if c.inside_connector.valid then c.inside_connector.destroy() end
end
Fluid.tick = function() end

return Fluid