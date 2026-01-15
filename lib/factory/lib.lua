local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local metadata = require("__FactorissimoLib__/lib/factory/metadata") -- Исправил json на metadata для консистентности

local M = {}
-- Используем локальную таблицу для хранения данных фабрик внутри текущего этапа (Data или Runtime)

M.factories = M.factories or {}

M.allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

----------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------

function M.cleanup_name(name)
    if not name then return nil end
    return name:gsub("%-instantiated", ""):gsub("%-starter%-pack", "")
end

function M.get_factory_data(name)
    return M.factories[M.cleanup_name(name)]
end

function M.is_factory(name)
    if not name then return false end
    local clean_name = M.cleanup_name(name)
    return M.factories[clean_name] ~= nil
end

function M.check_factory_data(factory_data)
    if not factory_data then
        error("Invalid factory data: factory_data table is nil")
    end
    local fields = {"type", "name", "tier", "outside_size", "inside_size", "color", "graphics"}
    for _, field in ipairs(fields) do
        if factory_data[field] == nil then
            error("Invalid factory data: '" .. field .. "' field is missing")
        end
    end
    if not M.allowed_factory_types[factory_data.type] then
        error("Invalid factory data: 'type' " .. tostring(factory_data.type) .. " is not allowed")
    end
    if M.factories[factory_data.name] then
        error("Factory with name " .. factory_data.name .. " already exists")
    end
end

----------------------------------------------------------------
-- DATA STAGE (Загрузка прототипов)
----------------------------------------------------------------

if data then
    local TilesLib = require("__FactorissimoLib__/lib/tiles")
    local FactoryPrototypes = require("__FactorissimoLib__/lib/factory/prototypes")
    local Alternatives = require("__FactorissimoLib__/lib/alternatives")

    function M.add_factory(factory_data)
        M.check_factory_data(factory_data)

        -- 3. Установка дефолтов
        factory_data.conditioned = factory_data.conditioned or false
        factory_data.pattern = factory_data.pattern or "00"
        factory_data.subgroup = factory_data.subgroup or "factorissimo-factories"
        
        -- 4. Создание визуальных компонентов
        factory_data.wall_tile_name = TilesLib.createColoredTile("factory-wall", factory_data.color)
        factory_data.floor_tile_name = TilesLib.createColoredTile("factory-floor", factory_data.color)

        M.factories[factory_data.name] = factory_data
        Alternatives.register_category("factory-data-" .. factory_data.name, factory_data)
    end

    function M.make_factory_prototypes(factory_data)
        factory_data = Alternatives.apply_alternatives("factory-data-" .. factory_data.name, factory_data)
        local prototypes = {}
        local creators = {
            FactoryPrototypes.make_entity,
            FactoryPrototypes.make_item,
            FactoryPrototypes.make_instantiated_item,
            FactoryPrototypes.make_recipe,
            FactoryPrototypes.make_technology
        }
        
        for _, create in ipairs(creators) do
            local p = create(factory_data)
            if p then table.insert(prototypes, p) end
        end
        return prototypes
    end

    function M.addToData()
        local all_prototypes = {}
        for _, fd in pairs(M.factories) do
            local pros = M.make_factory_prototypes(fd)
            for _, p in ipairs(pros) do table.insert(all_prototypes, p) end
        end
        data:extend(all_prototypes)
    end

----------------------------------------------------------------
-- RUNTIME STAGE (control.lua)
----------------------------------------------------------------
else
    -- В Runtime мы не можем смотреть data.raw, используем API прототипов
    -- Этот блок наполняет таблицу factories данными из JSON
    local function load_all_factories()
        -- Проходим по всем типам сущностей, которые могут быть фабриками
        local types_to_check = base_prototypes.get_factory_entity_types() -- добавь нужные базовые типы

        for _, type_name in ipairs(types_to_check) do
            local protos = prototypes.get_entity_filtered({{filter = "type", type = type_name}})
            for name, prot in pairs(protos) do
                local factory_data = metadata.decode_metadata(prot)
                if factory_data then
                    factory_data.name = name
                    M.factories[name] = factory_data
                end
            end
        end
    end

    if #M.factories == 0 then load_all_factories() end

    function M.get_factory_data(name)
        return M.factories[M.cleanup_name(name)]
    end
end

return M