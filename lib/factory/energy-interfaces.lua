local M = {}

if data then

    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    -- Кэш для предотвращения повторного создания в рамках одного запуска
    local created_interfaces = {}

    local function make_box(size, offset)
        local r = size / 2 - offset
        return {{-r, -r}, {r, r}}
    end

    M.get_interface_name = function(size)
        return "factory-power-input-" .. size
    end

    M.create = function(size)
        local name = M.get_interface_name(size)
        
        -- Если уже создали в этом запуске, пропускаем
        if created_interfaces[name] then return name end
        
        -- Если уже существует в data.raw (создан другим модом), кэшируем и выходим
        if data.raw["electric-energy-interface"][name] then
            created_interfaces[name] = true
            return name
        end

        local interface = table.deepcopy(base_prototypes.energy_interface)
        
        interface.name = name
        interface.selection_box = make_box(size, 0.3)
        interface.collision_box = make_box(size, 0.3)

        data:extend({interface})
        
        created_interfaces[name] = interface
        log("Created energy interface for size: " .. size)
        
        return name
    end

end

return M