local util = require("util")

local M = {}

function M.make_metadata(factory_data)
    return {
        tier = factory_data.tier,
        inside_size = factory_data.inside_size,
        outside_size = factory_data.outside_size,
        conditioned = factory_data.conditioned,
        pattern = factory_data.pattern,
        connections_per_side = factory_data.connections_per_side,
        -- Сохраняем цвет как простую таблицу
        color = {
            r = factory_data.color.r,
            g = factory_data.color.g,
            b = factory_data.color.b
        }
    }
end

function M.encode_metadata(tablev, prototype)
    if not tablev or not prototype then return nil end

    local json = util.table_to_json(json)
    if prototype.localised_description then
        prototype.localised_description = {
            "?", 
            prototype.localised_description, -- Попытка найти описание в локализации
            {"", "Error: localised_description"},
            {"", "thisismetadata", json}
        }
    end
end

function M.decode_metadata(prototype)
    if not prototype.localised_description then return nil end

    local json_string = nil
    for _, desc in ipairs(prototype.localised_description) do
        if desc[1] == "" and desc[2] == "thisismetadata" then
            json_string = desc[3]
            break
        end
    end

    if not json_string then return nil end

    local json = util.json_to_table(json_string)
    if not json then return nil end

    return json
end