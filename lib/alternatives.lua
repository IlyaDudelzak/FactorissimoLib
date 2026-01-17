local prototype_table = require("__FactorissimoLib__/lib/prototype-table")
local M = {}

-- Названия наших технических прототипов
M.PATCHES_BANK = "factorissimo-alternatives-patches-data-bank"
M.CATEGORIES_BANK = "factorissimo-alternatives-allowed-categories-data-bank"

-- Инициализация банков при первом подключении
if not prototype_table.exists(M.PATCHES_BANK) then
    prototype_table.create(M.PATCHES_BANK)
end
if not prototype_table.exists(M.CATEGORIES_BANK) then
    prototype_table.create(M.CATEGORIES_BANK)
end

-- Условия (без изменений)
M.conditions = {
    ["always"] = function() return true end,
    ["mod"] = function(name) return mods and mods[name] ~= nil end,
    ["setting"] = function(name) 
        return settings.startup[name] and settings.startup[name].value 
    end
}

local function check_condition(candidate)
    local func = M.conditions[candidate.type]
    return func and func(table.unpack(candidate.args)) or false
end

local function deep_merge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            deep_merge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

----------------------------------------------------------------
-- УПРАВЛЕНИЕ КАТЕГОРИЯМИ
----------------------------------------------------------------

M.register_category = function(category)
    -- Пишем напрямую в банк данных, чтобы другие моды увидели это
    prototype_table.add(M.CATEGORIES_BANK, category, true)
    log("Registered alternatives category: " .. category)
end

local function validate_category(category)
    local allowed = prototype_table.get_table(M.CATEGORIES_BANK)
    if not allowed or not allowed[category] then
        error("Unregistered alternatives category: " .. tostring(category))
    end
end

----------------------------------------------------------------
-- ПАТЧИ
----------------------------------------------------------------

M.add_patch = function(category, patch_data, cond_type, cond_args, priority)
    validate_category(category)

    -- Читаем текущий список патчей из банка
    local all_patches = prototype_table.get_table(M.PATCHES_BANK) or {}
    all_patches[category] = all_patches[category] or {}

    table.insert(all_patches[category], {
        data = patch_data,
        type = cond_type or "always",
        args = type(cond_args) == "table" and cond_args or {cond_args},
        priority = priority or 50
    })

    -- Сохраняем обратно обновленный список
    prototype_table.set(M.PATCHES_BANK, all_patches)
end

M.apply_alternatives = function(category, base_data)
    validate_category(category)
    
    -- Получаем актуальные патчи из хранилища
    local all_patches = prototype_table.get_table(M.PATCHES_BANK) or {}
    local result = table.deepcopy(base_data)
    
    local category_patches = all_patches[category]
    if not category_patches then return result end
    
    -- Фильтруем по условиям
    local active_patches = {}
    for _, p in ipairs(category_patches) do
        if check_condition(p) then table.insert(active_patches, p) end
    end
    
    -- Сортируем по приоритету
    table.sort(active_patches, function(a, b) return a.priority < b.priority end)
    
    -- Применяем
    for _, p in ipairs(active_patches) do
        deep_merge(result, p.data)
    end
    
    return result
end

return M