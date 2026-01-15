local util = require("util")

local M = {}

-- 1. Подготовка чистой таблицы (без изменений)
function M.make_metadata(factory_data)
    return {
        tier = factory_data.tier,
        inside_size = factory_data.inside_size,
        outside_size = factory_data.outside_size,
        conditioned = factory_data.conditioned,
        pattern = factory_data.pattern,
        connections_per_side = factory_data.connections_per_side,
        color = {
            r = factory_data.color.r,
            g = factory_data.color.g,
            b = factory_data.color.b
        }
    }
end

-- 2. Кодирование
function M.encode_metadata(metadata_table, prototype)
    if not metadata_table or not prototype then return end

    -- ИСПРАВЛЕНО: было util.table_to_json(json), а нужно (metadata_table)
    local json_string = util.table_to_json(metadata_table)
    
    -- Берем существующее описание или создаем стандартный ключ
    local current_desc = prototype.localised_description or {"entity-description." .. prototype.name}

    -- Формируем структуру
    prototype.localised_description = {
        "?", 
        current_desc, 
        -- Маркер "thisismetadata" гарантирует, что мы не распарсим чужие данные
        {"", "thisismetadata", json_string} 
    }
end

-- 3. Декодирование
function M.decode_metadata(prototype)
    local l_desc = prototype.localised_description
    if not l_desc or type(l_desc) ~= "table" then return nil end

    local json_string = nil
    for i = 2, #l_desc do
        local element = l_desc[i]
        if type(element) == "table" and element[1] == "" and element[2] == "thisismetadata" then
            json_string = element[3]
            break
        end
    end

    if not json_string then return nil end
    return util.json_to_table(json_string)
end

return M