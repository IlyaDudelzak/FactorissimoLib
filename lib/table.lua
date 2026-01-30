
table.map = function(tbl, f, ...)
    local result = {}
    for k, v in pairs(tbl) do
        result[k] = f(v, k, ...)
    end
    return result
end

table.filter = function(tbl, f, ...)
    local result = {}
    for k, v in pairs(tbl) do
        if f(v, k, ...) then result[k] = v end
    end
    return result
end

table.find = function(tbl, f, ...)
    if type(f) ~= "function" then
        for k, v in pairs(tbl) do if v == f then return v, k end end
        return nil
    end
    for k, v in pairs(tbl) do
        if f(v, k, ...) then return v, k end
    end
    return nil
end

table.any = function(tbl, f, ...)
    return table.find(tbl, f, ...) ~= nil
end

table.all = function(tbl, f, ...)
    for k, v in pairs(tbl) do
        if not f(v, k, ...) then return false end
    end
    return true
end

table.is_empty = function(tbl)
    return next(tbl) == nil
end

table.keys = function(tbl)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    return keys
end

table.values = function(tbl)
    local values = {}
    for _, v in pairs(tbl) do table.insert(values, v) end
    return values
end

table.first = function(tbl)
    for _, v in pairs(tbl) do return v end
    return nil
end

table.last = function(tbl)
    local last = nil
    for _, v in pairs(tbl) do last = v end
    return last
end

table.array_last = function(tbl)
    return tbl[#tbl]
end

table.invert = function(tbl)
    local result = {}
    for k, v in pairs(tbl) do result[v] = k end
    return result
end

table.merge = function(...)
    local result = {}
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        if type(t) == 'table' then
            for k, v in pairs(t) do result[k] = v end
        end
    end
    return result
end

table.array_combine = function(...)
    local result = {}
    for i = 1, select('#', ...) do
        local t = select(i, ...)
        if type(t) == 'table' then
            for _, v in ipairs(t) do table.insert(result, v) end
        end
    end
    return result
end

---Reverses an array in-place and returns it.
---@param tbl any[]
---@return any[]
table.reverse = function(tbl)
    for i = 1, #tbl / 2 do
        tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
    end
    return tbl
end

local function shuffle(t)
    local keys = {}
    local n = 0
    for k in pairs(t) do
        n = n + 1
        keys[n] = k
    end

    while n > 1 do
        local k = math.random(n)
        keys[n], keys[k] = keys[k], keys[n]
        n = n - 1
    end

    return keys
end
---Like normal pairs(), but in deterministic randomized order
---@param t table
---@return fun():any, any
function factorissimo.shuffled_pairs(t)
    local shuffled_keys = shuffle(t)
    local i = 0
    return function()
        i = i + 1
        local key = shuffled_keys[i]
        if key then
            return key, t[key]
        end
    end
end

---Returns a new array with duplicates removed.
---@param tbl any[]
---@return any[]
table.dedupe = function(tbl)
    local seen = {}
    local result = {}
    for _, v in pairs(tbl) do
        if not seen[v] then
            table.insert(result, v)
            seen[v] = true
        end
    end
    return result
end
