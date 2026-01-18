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

function has_metadata(prototype)
    if not prototype or not prototype.localised_description then return false end
    if prototype.localised_description[1] ~= "?" then
        return false
    end
    for i = 1, #prototype.localised_description do
        local element = prototype.localised_description[i]
        if type(element) == "table" and element[2] == "thisismetadata" then
            return true
        end
    end
    return false
end

-- 2. Кодирование (Data Stage)
function M.encode_metadata(metadata_table, prototype)
    if not metadata_table or not prototype then return end

    local data_string = serpent.line(metadata_table)
    
    -- 1. Разбиваем длинную строку на части по 190 символов (с запасом)
    local chunks = {""} -- Первый элемент "" для конкатенации в Factorio
    table.insert(chunks, "thisismetadata") -- Маркер
    
    for i = 1, #data_string, 190 do
        table.insert(chunks, data_string:sub(i, i + 189))
    end

    -- 2. Берем старое описание (твоя защита от рекурсии)
    local current_desc = has_metadata(prototype) and prototype.localised_description[2] 
                         or (prototype.localised_description or {"entity-description." .. prototype.name})

    -- 3. Собираем финальную структуру
    prototype.localised_description = {
        "?", 
        current_desc,
        {"", "placeholder"}, -- Плейсхолдер для корректной работы Factorio с
        chunks -- Теперь это таблица {"", "thisismetadata", "chunk1", "chunk2"...}
    }
end

-- 3. Декодирование (Runtime Stage)
function M.decode_metadata(prototype)
    local l_desc = prototype.localised_description
    if not l_desc or type(l_desc) ~= "table" then return nil end

    for i = 1, #l_desc do
        local element = l_desc[i]
        -- Ищем наш блок по маркеру во втором индексе чанка
        if type(element) == "table" and element[2] == "thisismetadata" then
            -- Собираем все части строки, начиная с 3-го индекса
            local full_string = ""
            for j = 3, #element do
                full_string = full_string .. element[j]
            end
            
            local f, err = loadstring("return " .. full_string)
            if f then return f() end
        end
    end
    return nil
end

return M