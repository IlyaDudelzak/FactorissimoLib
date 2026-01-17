local M = {}

-- Стандартные цвета (tints)
M.tints = {
    {r = 1.0,   g = 1.0,   b = 0.0,   a = 1.0},
    {r = 1.0,   g = 0.0,   b = 0.0,   a = 1.0},
    {r = 0.223, g = 0.490, b = 0.858, a = 1.0},
    {r = 1.0,   g = 0.0,   b = 1.0,   a = 1.0}
}

-- Генерация светлых оттенков
M.light_tints = {}
for i, tint in ipairs(M.tints) do
    M.light_tints[i] = {}
    for color, amount in pairs(tint) do
        M.light_tints[i][color] = (amount - 0.5) / 2 + 0.5
    end
    M.light_tints[i].a = 1
end

-- Нормализация цвета (0-255 -> 0-1)
function M.color_normalize(color)
    if not color then return {r = 1, g = 1, b = 1, a = 1} end
    local r = color.r or color[1] or 0
    local g = color.g or color[2] or 0
    local b = color.b or color[3] or 0
    local a = color.a or color[4] or 1
    
    if r > 1 or g > 1 or b > 1 then
        r, g, b, a = r / 255, g / 255, b / 255, a / 255
    end
    
    return {r = r, g = g, b = b, a = a}
end

-- Смешивание цветов
function M.color_combine(a, b, percent)
    a = M.color_normalize(a)
    b = M.color_normalize(b)

    return {
        r = a.r * percent + b.r * (1 - percent),
        g = a.g * percent + b.g * (1 - percent),
        b = a.b * percent + b.b * (1 - percent),
        a = a.a * percent + b.a * (1 - percent)
    }
end

return M