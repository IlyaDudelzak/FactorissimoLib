local M = {}

local north = defines.direction.north
local east = defines.direction.east
local south = defines.direction.south
local west = defines.direction.west

local opposite = {[north] = south, [east] = west, [south] = north, [west] = east}
local DX = {[north] = 0, [east] = 1, [south] = 0, [west] = -1}
local DY = {[north] = -1, [east] = 0, [south] = 1, [west] = 0}

-- Проверка попадания в зону внутренней двери (ровно 10 клеток: -5 до 5)
local function is_in_internal_door_zone(offset, side_code, fd)
    if not fd.door or side_code ~= fd.door.side then return false end
    -- Внутренняя дверь: строго от -5 до 5
    return math.abs(offset) <= 5
end

-- Проверка на перекрытие портов (минимум 2 тайла между центрами)
local function is_overlapping(offset, used_offsets)
    for _, existing in ipairs(used_offsets) do
        if math.abs(offset - existing) < 2 then return true end
    end
    return false
end


local infos = {
    n = {dir = north, axis = "x", const = "y", sign = -1},
    s = {dir = south, axis = "x", const = "y", sign = 1},
    e = {dir = east,  axis = "y", const = "x", sign = 1},
    w = {dir = west,  axis = "y", const = "x", sign = -1}
}

local build_connection = function(id, offset, side_code, fd)
    local info = infos[side_code]

    local scale = (fd.outside_size / 2) / (fd.inside_size / 2)
    
    local in_pos = {x = 0, y = 0}
    in_pos[info.axis] = offset
    in_pos[info.const] = (fd.inside_size / 2 + 0.5) * info.sign

    local out_pos = {x = 0, y = 0}
    out_pos[info.axis] = offset * scale
    out_pos[info.const] = (fd.outside_size / 2) * info.sign

    return {
        id = id,
        outside_x = out_pos.x,
        outside_y = out_pos.y,
        inside_x = in_pos.x,
        inside_y = in_pos.y,
        indicator_dx = DX[info.dir],
        indicator_dy = DY[info.dir],
        direction_in = opposite[info.dir],
        direction_out = info.dir,
    }
end

M.connection_handlers = {manual = {}, manual_side = {}, automatic = {}}

-- MANUAL: Строгая проверка, ошибка при коллизии с дверью
function M.connection_handlers.manual.check(fd)
    if not fd.connections or type(fd.connections) ~= "table" then
        error("Manual handler requires 'connections' table for: " .. fd.name)
    end
end

function M.connection_handlers.manual.generate(fd)
    local connections = {}
    local side_codes = {"n", "s", "e", "w"}
    local source = fd.connections
    if not source.e then source.e = source.w end 

    for _, side in ipairs(side_codes) do
        local used_offsets = {}
        local count = 1
        local raw_offsets = source[side] or {}

        for _, val in ipairs(raw_offsets) do
            local pair = (val == 0) and {0} or {val, -val}
            for _, offset in ipairs(pair) do
                if is_in_internal_door_zone(offset, side, fd) then
                    error("CRITICAL: Manual port " .. offset .. " on side " .. side .. " hits 10-tile door zone in " .. fd.name)
                end
                if is_overlapping(offset, used_offsets) then
                    error("CRITICAL: Manual ports overlap on side " .. side .. " in " .. fd.name)
                end

                table.insert(used_offsets, offset)
                local id = side .. count
                connections[id] = build_connection(id, offset, side, fd)
                count = count + 1
            end
        end
    end
    return connections
end

-- MANUAL_SIDE: Авто-фильтрация дверной зоны без ошибок
function M.connection_handlers.manual_side.check(fd)
    if not fd.connections or #fd.connections == 0 then
        error("Manual_side requires 'connections' list for: " .. fd.name)
    end
end

function M.connection_handlers.manual_side.generate(fd)
    local connections = {}
    local side_codes = {"n", "s", "e", "w"}
    local offsets_list = fd.connections

    for _, side in ipairs(side_codes) do
        local used_offsets = {}
        local count = 1
        for _, val in ipairs(offsets_list) do
            local pair = (val == 0) and {0} or {val, -val}
            for _, offset in ipairs(pair) do
                if not is_in_internal_door_zone(offset, side, fd) and not is_overlapping(offset, used_offsets) then
                    table.insert(used_offsets, offset)
                    local id = side .. count
                    connections[id] = build_connection(id, offset, side, fd)
                    count = count + 1
                end
            end
        end
    end
    return connections
end

function M.connection_handlers.automatic.check(fd) error("Automatic connections are not implemented") end
function M.connection_handlers.automatic.generate(fd) error("Automatic connections are not implemented") end

M.check_connections = function(fd)
    local handler = M.connection_handlers[fd.handler]
    if not handler then error("Unknown handler: " .. tostring(fd.handler)) end
    handler.check(fd)
end

M.generate_connections = function(fd)
    local handler = M.connection_handlers[fd.handler]
    if not handler then error("Unknown handler: " .. tostring(fd.handler)) end
    return handler.generate(fd)
end

return M