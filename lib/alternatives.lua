local M = {}

-- 1. Condition registry
M.conditions = {
    ["always"] = function() return true end,
    ["mod"] = function(name) return mods and mods[name] ~= nil end,
    ["setting"] = function(name) 
        return settings.startup[name] and settings.startup[name].value 
    end
}

-- 2. Internal function to check conditions
local function check_condition(candidate)
    local func = M.conditions[candidate.type]
    if not func then 
        log("Warning: Unknown condition type: " .. tostring(candidate.type))
        return false 
    end
    return func(table.unpack(candidate.args))
end

-- 3. Recursive table merge (for applying patches)
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
-- GLOBAL REGISTRIES
----------------------------------------------------------------
M.overrides = {} -- For full object replacement
M.patches = {}   -- For partial parameter modification

-- Register an override (full replacement)
M.add_override = function(category, data, cond_type, cond_args, priority)
    M.overrides[category] = M.overrides[category] or {}
    table.insert(M.overrides[category], {
        data = data,
        type = cond_type or "always",
        args = type(cond_args) == "table" and cond_args or {cond_args},
        priority = priority or 50
    })
end

-- Register a patch (partial modification)
M.add_patch = function(category, patch_data, cond_type, cond_args, priority)
    M.patches[category] = M.patches[category] or {}
    table.insert(M.patches[category], {
        data = patch_data,
        type = cond_type or "always",
        args = type(cond_args) == "table" and cond_args or {cond_args},
        priority = priority or 50
    })
end

----------------------------------------------------------------
-- DATA PROCESSING
----------------------------------------------------------------

-- Applies all suitable patches and overrides to an object
M.apply_alternatives = function(category, base_data)
    local result = table.deepcopy(base_data)
    
    -- 1. First, look for overrides (pick the best one with max priority)
    local best_override = nil
    local max_p = -math.huge
    
    if M.overrides[category] then
        for _, candidate in ipairs(M.overrides[category]) do
            if check_condition(candidate) and candidate.priority > max_p then
                max_p = candidate.priority
                best_override = candidate.data
            end
        end
    end
    
    -- If an override is found, use it as the new base
    if best_override then
        result = table.deepcopy(best_override)
    end
    
    -- 2. Then apply ALL suitable patches (sorted by priority)
    if M.patches[category] then
        local active_patches = {}
        for _, p in ipairs(M.patches[category]) do
            if check_condition(p) then table.insert(active_patches, p) end
        end
        
        -- Sort patches so higher priority ones are applied last
        table.sort(active_patches, function(a, b) return a.priority < b.priority end)
        
        for _, p in ipairs(active_patches) do
            result = deep_merge(result, p.data)
        end
    end
    
    return result
end

return M