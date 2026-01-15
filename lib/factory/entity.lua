local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")
local Metadata = require("__FactorissimoLib__/lib/factory/metadata") -- Исправлено имя и путь
local Alternatives = require("__FactorissimoLib__/lib/alternatives")
local util = require("util")

local M = {}

local function make_box(size, offset)
    local r = size / 2 - offset
    return {{-r, -r}, {r, r}}
end

M.make_building = function(factory_data)
    -- ПРИМЕНЯЕМ АЛЬТЕРНАТИВЫ (Патчи/Оверрайды) перед созданием
    -- Это позволяет модам-аддонам менять factory_data на лету
    local fd = Alternatives.apply_alternatives("factory-data-" .. factory_data.name, factory_data)
    
    local name = fd.name
    local prototype = table.deepcopy(base_prototypes.entity[fd.type])
    
    prototype.name = name
    prototype.icon = fd.graphics.icon
    prototype.icon_size = fd.graphics.icon_size
    prototype.map_color = fd.color
    prototype.collision_box = make_box(fd.outside_size, 0.2)
    prototype.selection_box = make_box(fd.outside_size, 0.2)
    prototype.max_health = fd.max_health or (math.pow(2.5, fd.tier) * 2000)
    
    -- СЕРИАЛИЗАЦИЯ (Используем уже измененные данные fd)
    Metadata.encode_metadata(Metadata.make_metadata(fd), prototype)
    
    if fd.type == "factory" then
        prototype.minable.result = name .. "-instantiated"
        prototype.placeable_by.item = name
        prototype.pictures = fd.graphics.pictures
    elseif fd.type == "space-platform-hub" then
        prototype.weight = 1000 * fd.outside_size * fd.outside_size
    end

    return prototype
end

return M