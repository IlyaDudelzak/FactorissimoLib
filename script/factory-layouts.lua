require "script.factory-logic"

-- Fallback for `defines` during development
if not defines then
    defines = {
        direction = {
            north = 0,
            east = 2,
            south = 4,
            west = 6,
        }
    }
end

-- Ensure `storage` is initialized
storage = storage or {}

local layout_generators = layout_generators or {}

local north = defines.direction.north
local east = defines.direction.east
local south = defines.direction.south
local west = defines.direction.west

local DX = {[north] = 0, [east] = 1, [south] = 0, [west] = -1}
local DY = {[north] = -1, [east] = 0, [south] = 1, [west] = 0}
local opposite = {[north] = south, [east] = west, [south] = north, [west] = east}

local function make_connection(id, outside_x, outside_y, inside_x, inside_y, direction_out)
    return {
        id = id,
        outside_x = outside_x,
        outside_y = outside_y,
        inside_x = inside_x,
        inside_y = inside_y,
        indicator_dx = DX[direction_out],
        indicator_dy = DY[direction_out],
        direction_in = opposite[direction_out],
        direction_out = direction_out,
    }
end

local function make_quality_connection(id, outside_x, outside_y, inside_x, inside_y, direction_out, quality)
    local connection = make_connection(id, outside_x, outside_y, inside_x, inside_y, direction_out)
    connection.quality = quality
    return connection
end

-- Example layout generator (can be extended with more layouts)
layout_generators["factory-1"] = {
    name = "factory-1",
    tier = 1,
    inside_size = 30,
    outside_size = 10,
    inside_door_x = 0,
    inside_door_y = 16,
    outside_door_x = 0,
    outside_door_y = 4,
    connections = {
        w1 = make_connection("w1", -4.5, -2.5, -15.5, -9.5, west),
        e1 = make_connection("e1", 4.5, -2.5, 15.5, -9.5, east),
    },
    rectangles = {
        {x1 = -16, x2 = 16, y1 = -16, y2 = 16, tile = "factory-wall-1"},
        {x1 = -15, x2 = 15, y1 = -15, y2 = 15, tile = "factory-floor"},
    },
}

-- Function to register layouts globally
local function register_layouts()
    storage.layout_generators = storage.layout_generators or {}
    for name, layout in pairs(layout_generators) do
        storage.layout_generators[name] = layout
    end
end

factorissimo.on_event(factorissimo.events.on_init(), register_layouts)

return layout_generators
