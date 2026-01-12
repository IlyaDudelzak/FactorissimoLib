-- Table utilities
table.map = function(tbl, f, ...)
    local result = {}
    for k, v in pairs(tbl) do result[k] = f(v, k, ...) end
    return result
end

table.filter = function(tbl, f, ...)
    local result = {}
    local is_array = #tbl > 0
    if is_array then
        for i, v in pairs(tbl) do if f(v, i, ...) then result[#result + 1] = v end end
    else
        for k, v in pairs(tbl) do if f(v, k, ...) then result[k] = v end end
    end
    return result
end

table.find = function(tbl, f, ...)
    if type(f) == "function" then
        for k, v in pairs(tbl) do if f(v, k, ...) then return v, k end end
    else
        for k, v in pairs(tbl) do if v == f then return v, k end end
    end
    return nil
end

table.any = function(tbl, f, ...) return table.find(tbl, f, ...) ~= nil end

table.all = function(tbl, f, ...)
    if type(f) == "function" then
        for k, v in pairs(tbl) do if not f(v, k, ...) then return false end end
    else
        for k, v in pairs(tbl) do if v ~= f then return false end end
    end
    return true
end

table.is_empty = function(tbl) return next(tbl) == nil end
table.keys = function(tbl)
    local keys = {}
    for k, _ in pairs(tbl) do keys[#keys + 1] = k end
    return keys
end
table.values = function(tbl)
    local values = {}
    for _, v in pairs(tbl) do table.insert(values, v) end
    return values
end
table.invert = function(tbl)
    local result = {}
    for k, v in pairs(tbl) do result[v] = k end
    return result
end
table.merge = function(...)
    local result = {}
    for _, tbl in pairs {...} do
        for k, v in pairs(tbl) do result[k] = v end
    end
    return result
end
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

-- String utilities
string.split = function(s, seperator)
    local result = {}
    for match in (s .. seperator):gmatch("(.-)" .. seperator) do
        result[#result + 1] = match
    end
    return result
end
string.is_digit = function(s) return s:match("%d") ~= nil end
string.starts_with = function(s, start) return s:sub(1, #start) == start end

-- Color utilities
factorissimo.color_normalize = function(color)
    local r = color.r or color[1]
    local g = color.g or color[2]
    local b = color.b or color[3]
    local a = color.a or color[4] or 1
    if r > 1 then r = r / 255 end
    if g > 1 then g = g / 255 end
    if b > 1 then b = b / 255 end
    if a > 1 then a = a / 255 end
    return {r = r, g = g, b = b, a = a}
end

factorissimo.color_combine = function(a, b, percent)
    a = factorissimo.color_normalize(a)
    b = factorissimo.color_normalize(b)
    return {
        r = a.r * percent + b.r * (1 - percent),
        g = a.g * percent + b.g * (1 - percent),
        b = a.b * percent + b.b * (1 - percent),
        a = a.a * percent + b.a * (1 - percent)
    }
end