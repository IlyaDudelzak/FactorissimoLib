local M = {}
local metadata = require("__FactorissimoLib__/lib/metadata")

M.bank_type = "sprite"

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    function M.exists(name)
        -- Сначала проверяем, существует ли вообще категория M.bank_type
        if not data.raw[M.bank_type] then 
            return false 
        end
        -- Если категория есть, проверяем наличие конкретного объекта
        if not data.raw[M.bank_type][name] then
            return false
        end
        if not metadata.decode_metadata(data.raw[M.bank_type][name]) then
            return false
        end
        return true
    end

    function error_if_not_exists(name)
        -- Сначала проверяем, существует ли вообще категория M.bank_type
        if not data.raw[M.bank_type] then 
            error("No item-request prototypes found.")
        end
        -- Если категория есть, проверяем наличие конкретного объекта
        if not data.raw[M.bank_type][name] then
            error("No item-request prototype found for name: " .. name)
        end
        if not metadata.decode_metadata(data.raw[M.bank_type][name]) then
            error("Failed to decode metadata for item-request prototype: " .. name)
        end
        return true 
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
        local prototype = data.raw[M.bank_type][name]
        if not prototype then error("Prototype bank " .. name .. " not found.") end
        
        metadata.encode_metadata(data_table, prototype)
        data.raw[M.bank_type][name] = prototype
        return prototype
    end

    -- Универсальное добавление: если передан key — пишем по ключу, если нет — в конец списка
    function M.add(name, key_or_value, value)
        local prototype = data.raw[M.bank_type][name]
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
        data.raw[M.bank_type][name] = prototype

        return prototype
    end
    
    -- Чтение всей таблицы
    function M.get_table(name)
        error_if_not_exists(name)
        local prototype = data.raw[M.bank_type][name]
        return metadata.decode_metadata(prototype)
    end
else
    function M.exists(name)
        -- Сначала проверяем, существует ли вообще категория M.bank_type
        if not prototypes[M.bank_type] then 
            return false 
        end
        -- Если категория есть, проверяем наличие конкретного объекта
        if not prototypes[M.bank_type][name] then
            return false
        end
        if not metadata.decode_metadata(prototypes[M.bank_type][name]) then
            return false
        end
        return true
    end

    function error_if_not_exists(name)
        -- Сначала проверяем, существует ли вообще категория M.bank_type
        if not prototypes[M.bank_type] then 
            error("No item-request prototypes found.")
        end
        -- Если категория есть, проверяем наличие конкретного объекта
        if not prototypes[M.bank_type][name] then
            error("No item-request prototype found for name: " .. name)
        end
        if not metadata.decode_metadata(prototypes[M.bank_type][name]) then
            error("Failed to decode metadata for item-request prototype: " .. name)
        end
        return true 
    end
    -- Чтение всей таблицы
    function M.get_table(name)
        error_if_not_exists(name)
        local prototype = prototypes[M.bank_type][name]
        return metadata.decode_metadata(prototype)
    end
end

return M