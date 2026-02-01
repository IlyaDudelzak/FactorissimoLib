local FactoryLib = require("__FactorissimoLib__/lib/factory/lib")
local layout_generator = require("__FactorissimoLib__/lib/factory/layout-generator")
local constants = require("constants")
local utility = require("utility")

local M = {}

local function get_or_create_factory_surface(name, force)
    local planet = game.planets[name]
    if not planet then return nil end
    local surface = planet.surface
    if not surface then
        surface = planet.create_surface()
        surface.set_chunk_generated_status({0, 0}, defines.chunk_generated_status.entities)
        surface.set_chunk_generated_status({-1, 0}, defines.chunk_generated_status.entities)
        surface.set_chunk_generated_status({0, -1}, defines.chunk_generated_status.entities)
        surface.set_chunk_generated_status({-1, -1}, defines.chunk_generated_status.entities)
        surface.daytime = 0.5
        surface.freeze_daytime = true
        force.set_surface_hidden(surface, false)
        force.set_cease_fire(force, true)
    end
    return surface
end

function M.get_spiral_coords(n)
    if n == 0 then return {x = 0, y = 0} end
    local r = math.floor((math.sqrt(n + 1) - 1) / 2) + 1
    local p = (8 * r * (r - 1)) / 2
    local en = n - p
    local ed = 2 * r
    local pos = math.floor(en / ed)
    local off = en % ed
    if pos == 0 then return {x = r, y = off - r + 1}
    elseif pos == 1 then return {x = r - off - 1, y = r}
    elseif pos == 2 then return {x = -r, y = r - off - 1}
    else return {x = -r + off + 1, y = -r}
    end
end

local CHUNK_SPACING = 16 

function M.create_factory(building)
    local factory_data = FactoryLib.get_factory_data(building.name)
    if not factory_data then return nil end

    local current_surface = building.surface
    local target_surface

    if current_surface.name:match("%-factory%-floor$") then
        target_surface = current_surface
    else
        local target_name = current_surface.name .. "-factory-floor"
        target_surface = get_or_create_factory_surface(target_name, building.force)
    end
    
    if not target_surface then return nil end

    storage.surface_counters = storage.surface_counters or {}
    local n = storage.surface_counters[target_surface.index] or 0
    storage.surface_counters[target_surface.index] = n + 1

    local coords = M.get_spiral_coords(n)
    local cx, cy = coords.x * CHUNK_SPACING, coords.y * CHUNK_SPACING

    local factory = {
        id = (storage.next_factory_id or 1),
        outside_entity = building,
        inside_surface = target_surface,
        inside_x = 32 * cx,
        inside_y = 32 * cy,
        layout = factory_data.layout
    }
    storage.next_factory_id = (storage.next_factory_id or 1) + 1

    target_surface.request_to_generate_chunks({factory.inside_x, factory.inside_y}, 1)
    target_surface.force_generate_chunk_requests()

    M.render_factory_interior(factory)
    
    target_surface.create_entity{
        name = "factorissimo-factory-radar",
        position = {factory.inside_x, factory.inside_y},
        force = building.force,
        create_build_effect_smoke = false
    }

    building.force.chart(target_surface, {
        {factory.inside_x - 64, factory.inside_y - 64},
        {factory.inside_x + 64, factory.inside_y + 64}
    })
    
    return factory
end

function M.render_factory_interior(factory)
    local tiles = {}
    local layout = factory.layout
    if not layout then return end

    local off_x, off_y = factory.inside_x, factory.inside_y

    if layout.rectangles then
        for _, rect in pairs(layout.rectangles) do
            for x = rect.x1, rect.x2 - 1 do
                for y = rect.y1, rect.y2 - 1 do
                    table.insert(tiles, {name = rect.tile, position = {off_x + x, off_y + y}})
                end
            end
        end
    end

    if layout.mosaics then
        for _, mosaic in pairs(layout.mosaics) do
            layout_generator.add_tile_mosaic(tiles, mosaic.tile, off_x + mosaic.x1, off_y + mosaic.y1, off_x + mosaic.x2, off_y + mosaic.y2, mosaic.pattern)
        end
    end
    
    if #tiles > 0 then
        factory.inside_surface.set_tiles(tiles, true)
    end
end

function M.handle_factory_placed(event)
    local entity = event.entity or event.created_entity
    if not entity or not entity.valid then return end
    
    local factory_data = FactoryLib.get_factory_data(entity.name)
    if not factory_data then return end

    local item_name = ""
    if event.consumed_items and not event.consumed_items.is_empty() then
        local stack = event.consumed_items[1]
        if stack and stack.valid_for_read then
            item_name = stack.name
        end
    end

    if not item_name:match("%-instantiated$") then
        local factory = M.create_factory(entity)
        if not factory then return end
        
        local power_input_name = "factory-power-input-" .. factory_data.outside_size
        
        if prototypes.entity[power_input_name] then
            local power_input = entity.surface.create_entity{
                name = power_input_name,
                position = entity.position,
                force = entity.force,
                raise_built = true
            }
            
            if power_input then
                power_input.destructible = false
                power_input.minable = false
            end
        end
    end
end

factorissimo.on_event(factorissimo.events.on_built(), M.handle_factory_placed)

return M