local M = {}

-- Константы направлений Factorio
local north = defines.direction.north
local east = defines.direction.east
local south = defines.direction.south
local west = defines.direction.west

-- Таблицы соответствий для инверсии и смещений индикаторов
local opposite = {[north] = south, [east] = west, [south] = north, [west] = east}
local DX = {[north] = 0, [east] = 1, [south] = 0, [west] = -1}
local DY = {[north] = -1, [east] = 0, [south] = 1, [west] = 0}

-- Метаданные для осей каждой стороны
local side_infos = {
    n = {dir = north, axis = "x", const = "y", sign = -1},
    s = {dir = south, axis = "x", const = "y", sign = 1},
    e = {dir = east,  axis = "y", const = "x", sign = 1},
    w = {dir = west,  axis = "y", const = "x", sign = -1}
}

--- Вспомогательная функция: проверка попадания во внутреннюю зону двери (-5 до 5)
local function is_in_internal_door_zone(inner_pos, side_code, fd)
    if not fd.door or side_code ~= fd.door.side then return false end
    -- Блокируем, если внутренняя координата попадает в проем
    return math.abs(inner_pos) <= 5
end

--- Проверка на наложение портов (минимум 2 тайла между центрами)
local function is_overlapping(pos, used_positions)
    for _, existing in ipairs(used_positions) do
        if math.abs(pos - existing) < 2 then return true end
    end
    return false
end

--- Сборка объекта соединения
local function build_connection(id, connection_data, side_code, fd)
    local out_offset = connection_data[1] -- Наружная координата
    local in_offset  = connection_data[2] -- Внутренняя координата
    local quality    = connection_data[3] or 0 -- Качество (если нет, то 0)
    
    local info = side_infos[side_code]
    
    -- Позиция внутри: по оси axis ставим смещение, по const — край стены + 0.5
    local in_pos = {x = 0, y = 0}
    in_pos[info.axis] = in_offset
    in_pos[info.const] = (fd.inside_size / 2 + 0.5) * info.sign

    -- Позиция снаружи: край внешней стены
    local out_pos = {x = 0, y = 0}
    out_pos[info.axis] = out_offset
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
        quality = quality
    }
end

--- Функция зеркалирования: возвращает список из одной или двух записей
local function get_mirrored_entries(entry)
    local out_pos, in_pos, q = entry[1], entry[2], entry[3]
    if out_pos == 0 and in_pos == 0 then
        return { entry }
    end
    return {
        entry,
        { -out_pos, -in_pos, q } -- Зеркалим обе координаты, сохраняем качество
    }
end

M.connection_handlers = {manual = {}, manual_side = {}, automatic = {}}

-- MANUAL: Каждая сторона настраивается отдельно
function M.connection_handlers.manual.check(fd)
    if not fd.connections or type(fd.connections) ~= "table" then
        error("Manual handler requires side-specific tables (n,s,e,w) for: " .. fd.name)
    end
end

function M.connection_handlers.manual.generate(fd)
    local connections = {}
    local side_codes = {"n", "s", "e", "w"}
    local source = fd.connections
    if not source.e then source.e = source.w end

    for _, side in ipairs(side_codes) do
        local used_in_positions = {}
        local count = 1
        local raw_list = source[side] or {}

        for _, entry in ipairs(raw_list) do
            local pairs = get_mirrored_entries(entry)
            for _, conn_data in ipairs(pairs) do
                local in_pos = conn_data[2]
                
                if is_in_internal_door_zone(in_pos, side, fd) then
                    error("CRITICAL: Manual port (in:" .. in_pos .. ") overlaps door on side " .. side .. " in " .. fd.name)
                end
                
                table.insert(used_in_positions, in_pos)
                local id = side .. count
                connections[id] = build_connection(id, conn_data, side, fd)
                count = count + 1
            end
        end
    end
    return connections
end

-- MANUAL_SIDE: Один список координат зеркалится на все 4 стены
function M.connection_handlers.manual_side.check(fd)
    if not fd.connections.connections or #fd.connections.connections == 0 then
        error("Manual_side requires 'connections' list for: " .. fd.name)
    end
end

function M.connection_handlers.manual_side.generate(fd)
    local connections = {}
    local side_codes = {"n", "s", "e", "w"}
    local raw_list = fd.connections.connections

    for _, side in ipairs(side_codes) do
        local used_in_positions = {}
        local count = 1
        for _, entry in ipairs(raw_list) do
            local pairs = get_mirrored_entries(entry)
            for _, conn_data in ipairs(pairs) do
                local in_pos = conn_data[2]
                
                -- В этом режиме просто пропускаем порты, попавшие в дверь
                if not is_in_internal_door_zone(in_pos, side, fd) then
                    if is_overlapping(in_pos, used_in_positions) then
                        error("CRITICAL: Overlapping ports in manual_side on side " .. side .. " for " .. fd.name)
                    end
                    
                    table.insert(used_in_positions, in_pos)
                    local id = side .. count
                    connections[id] = build_connection(id, conn_data, side, fd)
                    count = count + 1
                end
            end
        end
    end
    return connections
end

function M.connection_handlers.automatic.check(fd) error("Automatic not implemented") end
function M.connection_handlers.automatic.generate(fd) return {} end

-- Публичные API методы
M.check_connections = function(fd)
    local handler = M.connection_handlers[fd.connections.handler]
    if not handler then error("Unknown handler in " .. tostring(fd.name)) end
    handler.check(fd)
end

M.generate_connections = function(fd)
    local handler = M.connection_handlers[fd.connections.handler]
    if not handler then error("Unknown handler in " .. tostring(fd.name)) end
    return handler.generate(fd)
end

--- Проверяет наличие порта в указанной внутренней позиции
M.has_connection_at_pos = function(fd, x, y, min_quality)
    local connections = M.generate_connections(fd)
    local mq = min_quality or 0
    for _, conn in pairs(connections) do
        -- Сравнение с допуском 0.1 для корректности float-координат
        if math.abs(conn.inside_x - x) < 0.1 and math.abs(conn.inside_y - y) < 0.1 then
            return conn.quality >= mq
        end
    end
    return false
end

return M