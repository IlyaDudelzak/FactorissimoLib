local M = {}
local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local metadata = require("__FactorissimoLib__/lib/metadata")

function M.exists(name)
    -- Сначала проверяем, существует ли вообще категория "item-request"
    if not data.raw["item-request"] then 
        return false 
    end
    -- Если категория есть, проверяем наличие конкретного объекта
    return data.raw["item-request"][name] ~= nil
end

-- Создание нового хранилища (банка данных)
function M.create(name)
    local prototype = table.deepcopy(base_prototypes.data_bank)
    prototype.name = name
    -- Инициализируем пустой таблицей в формате метаданных
    metadata.encode_metadata({}, prototype)
    data:extend({prototype})
    return prototype
end

-- Запись всей таблицы целиком
function M.set(name, data_table)
    local prototype = data.raw["item-request"][name]
    if not prototype then error("Prototype bank " .. name .. " not found.") end
    
    metadata.encode_metadata(data_table, prototype)
    data.raw["item-request"][name] = prototype
    return prototype
end

-- Универсальное добавление: если передан key — пишем по ключу, если нет — в конец списка
function M.add(name, key_or_value, value)
    local prototype = data.raw["item-request"][name]
    if not prototype then error("Prototype bank " .. name .. " not found.") end
    
    local data_table = metadata.decode_metadata(prototype) or {}
    
    if value ~= nil then
        -- Случай M.add(name, key, value)
        data_table[key_or_value] = value
    else
        -- Случай M.add(name, value)
        table.insert(data_table, key_or_value)
    end
    
    metadata.encode_metadata(data_table, prototype)
    data.raw["item-request"][name] = prototype

    return prototype
end

-- Чтение всей таблицы
function M.get_table(name)
    local prototype = data.raw["item-request"][name]
    if not prototype then return nil end
    return metadata.decode_metadata(prototype)
end

return M