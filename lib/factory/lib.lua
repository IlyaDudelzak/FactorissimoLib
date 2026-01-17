local metadata = require("__FactorissimoLib__/lib/metadata")
local prototype_table = require("__FactorissimoLib__/lib/prototype-table")

local M = {}

M.factories = M.factories or {}
M.allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

-- Единый банк для ВСЕХ фабрик
M.GLOBAL_FACTORY_BANK = "factorissimo-global-factory-storage"

----------------------------------------------------------------
-- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
----------------------------------------------------------------

function M.prepare_factory_data(factory_data)
    if not factory_data then error("Factory data is nil") end
    local to_delete = {
        "max_health",
        "graphics", 
        "recipe", 
        "technology", 
        "recipe_alternatives", 
        "technology_alternatives"
    }
    for _, f in ipairs(to_delete) do
        factory_data[f] = nil
    end
    return factory_data
end

function M.cleanup_name(name)
    if not name then return nil end
    return name:gsub("%-instantiated", ""):gsub("%-starter%-pack", "")
end

function M.is_factory(name)
    local clean_name = M.cleanup_name(name)
    return M.factories[clean_name] ~= nil
end

function M.check_factory_data(factory_data)
    if not factory_data then error("Factory data is nil") end
    local fields = {"type", "name", "tier", "outside_size", "inside_size", "color", "graphics"}
    for _, field in ipairs(fields) do
        if factory_data[field] == nil then
            error("Field '" .. field .. "' is missing in factory: " .. tostring(factory_data.name))
        end
    end
    if not M.allowed_factory_types[factory_data.type] then
        error("Type " .. tostring(factory_data.type) .. " is not allowed")
    end
end

----------------------------------------------------------------
-- DATA STAGE
----------------------------------------------------------------

if data then
    local TilesLib = require("__FactorissimoLib__/lib/tiles")
    local FactoryPrototypes = require("__FactorissimoLib__/lib/factory/prototypes")
    local alternatives = require("__FactorissimoLib__/lib/alternatives")

    function M.add_factory(factory_data)
        M.check_factory_data(factory_data)

        -- Инициализируем глобальный банк, если его еще нет
        if not data.raw["item-request"][M.GLOBAL_FACTORY_BANK] then
            prototype_table.create(M.GLOBAL_FACTORY_BANK)
        end

        -- Установка дефолтов
        factory_data.conditioned = factory_data.conditioned or false
        factory_data.pattern = factory_data.pattern or "00"
        factory_data.subgroup = factory_data.subgroup or "factorissimo-factories"
        
        -- Сохраняем в локальную память текущего процесса
        M.factories[factory_data.name] = factory_data

        -- Записываем в ЕДИНЫЙ банк (добавляем или обновляем запись по имени фабрики)
        prototype_table.add(M.GLOBAL_FACTORY_BANK, factory_data.name, factory_data)

        -- Регистрируем категорию для патчей
        alternatives.register_category("factory-data-" .. factory_data.name)
    end

    function M.make_factory_prototypes(factory_data)
        -- 1. Сначала применяем патчи alternatives
        factory_data = alternatives.apply_alternatives("factory-data-" .. factory_data.name, factory_data)
        
        -- 2. Теперь создаем тайлы (после того как патчи могли изменить цвет)
        TilesLib.createColoredTile("factory-wall", factory_data.color)
        TilesLib.createColoredTile("factory-floor", factory_data.color)
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
            if p then 
                -- Вшиваем финальные данные в прототип для Runtime
                metadata.encode_metadata(factory_data, p)
                table.insert(prototypes, p) 
            end
        end
        return prototypes
    end

    function M.addToData()
        -- 1. Выкачиваем ВСЁ из единого банка
        local all_stored_factories = prototype_table.get_table(M.GLOBAL_FACTORY_BANK)
        if all_stored_factories then
            for name, fd in pairs(all_stored_factories) do
                M.factories[name] = fd
            end
        end

        -- 2. Генерируем прототипы
        for _, fd in pairs(M.factories) do
            data:extend(M.make_factory_prototypes(fd))
        end

        -- 3. Удаляем банк, чтобы не мусорить в игре
        data.raw["item-request"][M.GLOBAL_FACTORY_BANK] = nil
    end

----------------------------------------------------------------
-- RUNTIME STAGE (control.lua)
----------------------------------------------------------------
else
    local function load_all_factories()
        -- В рантайме просто собираем данные из существующих в мире прототипов
        local types_to_check = {"storage-tank", "space-platform-hub"}
        for _, type_name in ipairs(types_to_check) do
            local protos = prototypes.get_entity_filtered({{filter = "type", type = type_name}})
            for name, prot in pairs(protos) do
                local fd = metadata.decode_metadata(prot)
                if fd then
                    fd.name = name
                    M.factories[name] = fd
                end
            end
        end
    end

    load_all_factories()

    function M.get_factory_data(name)
        local clean = M.cleanup_name(name)
        return M.factories[clean]
    end
end

return M