local M = {}

-- [[ 1. Реестры ]]
M.patches = M.patches or {}
M.allowed_categories = M.allowed_categories or {} -- Таблица разрешенных категорий

-- [[ 2. Условия и Слияние (как прежде) ]]
M.conditions = {
    ["always"] = function() return true end,
    ["mod"] = function(name) return mods and mods[name] ~= nil end,
    ["setting"] = function(name) 
        return settings.startup[name] and settings.startup[name].value 
    end
}

local function check_condition(candidate)
    local func = M.conditions[candidate.type]
    if not func then return false end
    return func(table.unpack(candidate.args))
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

-- Регистрация новой категории. Вызывай это в lib.lua при создании группы фабрик.
M.register_category = function(category)
    M.allowed_categories[category] = true
    log("Registered alternatives category: " .. category)
end

-- Проверка, разрешена ли категория
local function validate_category(category)
    if not M.allowed_categories[category] then
        error("Attempted to use unregistered alternatives category: " .. tostring(category) .. 
              ". Make sure to call register_category first!")
    end
end

----------------------------------------------------------------
-- ПАТЧИ
----------------------------------------------------------------

M.add_patch = function(category, patch_data, cond_type, cond_args, priority)
    -- Проверка: можно ли патчить эту категорию?
    validate_category(category)

    M.patches[category] = M.patches[category] or {}
    table.insert(M.patches[category], {
        data = patch_data,
        type = cond_type or "always",
        args = type(cond_args) == "table" and cond_args or {cond_args},
        priority = priority or 50
    })
end

M.apply_alternatives = function(category, base_data)
    validate_category(category)
    
    local result = table.deepcopy(base_data)
    if not M.patches[category] then return result end
    
    local active_patches = {}
    for _, p in ipairs(M.patches[category]) do
        if check_condition(p) then table.insert(active_patches, p) end
    end
    
    table.sort(active_patches, function(a, b) return a.priority < b.priority end)
    
    for _, p in ipairs(active_patches) do
        result = deep_merge(result, p.data)
    end
    
    return result
end

return M