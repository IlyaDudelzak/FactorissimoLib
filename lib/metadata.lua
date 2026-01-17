local M = {}

-- 1. Подготовка чистой таблицы (Whitelist подход)
function M.make_metadata(factory_data)
    if not factory_data then return nil end
    return {
        tier = factory_data.tier,
        inside_size = factory_data.inside_size,
        outside_size = factory_data.outside_size,
        conditioned = factory_data.conditioned,
        pattern = factory_data.pattern,
        connections_per_side = factory_data.connections_per_side,
        color = factory_data.color and {
            r = factory_data.color.r,
            g = factory_data.color.g,
            b = factory_data.color.b
        } or nil
    }
end

-- 2. Кодирование (Data Stage)
function M.encode_metadata(metadata_table, prototype)
    if not metadata_table or not prototype then return end

    -- Используем serpent.line, он доступен в Data Stage и быстрее JSON
    local data_string = serpent.line(metadata_table)
    
    -- Сохраняем оригинальное описание (если оно есть)
    local current_desc = prototype.localised_description or {"entity-description." .. prototype.name}

    -- Структура: [1] - оператор, [2] - старое описание, [3] - наш маркер данных
    prototype.localised_description = {
        "", 
        current_desc, 
        {"", "\n", "thisismetadata", data_string} 
    }
end

-- 3. Декодирование (Runtime Stage)
function M.decode_metadata(prototype)
    -- В Runtime localised_description может быть как строкой, так и таблицей
    local l_desc = prototype.localised_description
    if not l_desc or type(l_desc) ~= "table" then return nil end

    local data_string = nil
    -- Ищем наш маркер в таблице локализации
    for i = 1, #l_desc do
        local element = l_desc[i]
        if type(element) == "table" and element[2] == "thisismetadata" then
            data_string = element[3]
            break
        end
    end

    if not data_string then return nil end

    -- Безопасно превращаем строку Serpent обратно в таблицу
    -- loadstring превращает строку в исполняемую функцию Lua
    local f, err = loadstring("return " .. data_string)
    if f then
        return f()
    else
        log("Factorissimo Error: Failed to decode metadata: " .. tostring(err))
        return nil
    end
end

return M