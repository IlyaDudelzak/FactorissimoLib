local util = require("util")

local Roboport = {}

-- 1. Звуковые и функциональные константы
Roboport.constants = {
    small_area_size = 1.5,
    medium_area_size = 6.5,
    large_area_size = 15,
}

-- 2. Типы объектов, которые роботы игнорируют внутри фабрик
local blacklisted_types = util.list_to_map {
    -- Рельсы и эстакады (Factorio 2.0 / Space Age)
    "legacy-curved-rail", "legacy-straight-rail", "straight-rail", 
    "curved-rail-a", "curved-rail-b", "half-diagonal-rail",
    "rail-ramp", "rail-support", "elevated-straight-rail", 
    "elevated-curved-rail-a", "elevated-curved-rail-b", "elevated-half-diagonal-rail",

    -- Транспортные средства
    "car", "spider-vehicle", "locomotive", "cargo-wagon", 
    "fluid-wagon", "artillery-wagon", "ship", "platform-hub"
}

-- 3. Генерация черного списка имен на основе прототипов
Roboport.blacklist = {}

if prototypes and prototypes.entity then
    for name, proto in pairs(prototypes.entity) do
        if blacklisted_types[proto.type] then
            Roboport.blacklist[name] = true
        end
    end
end

-- 4. Функция-хелпер для быстрой проверки
function Roboport.is_blacklisted(name)
    return Roboport.blacklist[name] or false
end

return Roboport