local M = {}

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    -- Кэш созданных объектов
    local created = {}

    -- Генератор индикаторов
    M.create_indicator = function(ctype, suffix, image_path)
        local name = "factory-connection-indicator-" .. ctype .. "-" .. suffix
        if created[name] then return name end

        local indicator = table.deepcopy(base_prototypes.connection_indicator)
        indicator.name = name
        indicator.localised_name = {"entity-name.factory-connection-indicator-" .. ctype}
        indicator.pictures.picture.sheet.filename = image_path
        
        data:extend({indicator})
        created[name] = true
        return name
    end

    -- Генератор силовых опор (копирует визуал с существующих)
    M.create_custom_pole = function(name, source_pole_name, supply_range)
        if created[name] then return name end
        
        local source = data.raw["electric-pole"][source_pole_name]
        if not source then return nil end

        local pole = table.deepcopy(base_prototypes.factory_power_pole)
        pole.name = name
        pole.icon = source.icon
        pole.icon_size = source.icon_size
        pole.pictures = table.deepcopy(source.pictures)
        pole.supply_area_distance = supply_range or 63
        
        data:extend({pole})
        created[name] = true
        return name
    end

    -- Создание вспомогательного айтема-настройки (единоразово)
    M.create_settings_item = function()
        if data.raw.item["factory-connection-indicator-settings"] then return end
        data:extend({{
            type = "item",
            name = "factory-connection-indicator-settings",
            icon = "__FactorissimoLib__/graphics/indicator/blueprint-settings.png",
            stack_size = 1,
            hidden = true,
            flags = {"not-stackable", "only-in-cursor"}
        }})
    end
end

return M