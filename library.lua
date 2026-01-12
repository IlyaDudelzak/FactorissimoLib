_G.factorissimo = _G.factorissimo or {}

-- Определение текущей стадии игры
if data and data.raw and not data.raw.item["iron-plate"] then
    factorissimo.stage = "settings"
elseif data and data.raw then
    factorissimo.stage = "data"
elseif script then
    factorissimo.stage = "control"
else
    factorissimo.stage = "unknown"
end

-- Общие расширения Lua (таблицы, строки, цвета)
require("lib.common")

-- Загрузка констант (направления, цвета и т.д.)
factorissimo.constants = require("lib.constants")

if factorissimo.stage == "data" then
    -- Модули для стадии создания прототипов
    factorissimo.alternatives = require("lib.alternatives")
    factorissimo.proto_utils = require("lib.prototype-functions")
    factorissimo.base_prototypes = require("lib.base-prototypes")
    factorissimo.tile_manager = require("lib.tiles")
    factorissimo.factory_manager = require("lib.factory.libat")
    
    -- Заглушка для функций событий в data stage
    factorissimo.on_event = function() end
elseif factorissimo.stage == "control" then
    -- Модули для рантайма (логика игры)
    require("lib.events")
    factorissimo.patterns = require("lib.patterns")
end

return factorissimo