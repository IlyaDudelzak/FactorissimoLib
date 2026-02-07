local M = {}

function M.check_door(fd)
    if not fd.door then
        error("Door data must be defined for factory: " .. tostring(fd.name))
    end

    local door = fd.door

    if door.side == nil then
        error("Outside door side must be defined for factory: " .. tostring(fd.name))
    end
    
    -- Теперь side — это таблица (благодаря твоей правке в factory_data)
    local sides = type(door.side) == "table" and door.side or {door.side}
    local valid_sides = {n = true, e = true, s = true, w = true}
    
    for _, side in ipairs(sides) do
        if not valid_sides[side] then
            error("Outside door side must be one of 'n', 'e', 's', 'w'. Got: " .. tostring(side))
        end
    end

    if not door.size then
        error("Outside door size must be defined for factory: " .. tostring(fd.name))
    end
    if door.size < 2 then
        error("Outside door size must be at least 2 for factory: " .. tostring(fd.name))
    end
end

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    function M.create_horizontal_door(fd)
        local door_name = "horizontal-factory-entrance-door-" .. tostring(fd.door.size)
        
        if data.raw["simple-entity-with-force"] and data.raw["simple-entity-with-force"][door_name] then
            return door_name
        end

        local door = table.deepcopy(base_prototypes.horizontal_entrance_door)
        door.name = door_name
        door.localised_name = {"factorissimo.horizontal_factory_entrance_door", tostring(fd.door.size)}

        local ext_half_width = fd.door.size / 2 + 0.5
        door.collision_box = {{-ext_half_width, -0.5}, {ext_half_width, 0.5}}
        door.selection_box = {{-ext_half_width, -0.5}, {ext_half_width, 0.5}}
        data:extend({door})
        return door.name
    end

    function M.create_vertical_door(fd)
        local door_name = "vertical-factory-entrance-door-" .. tostring(fd.door.size)
        
        if data.raw["simple-entity-with-force"] and data.raw["simple-entity-with-force"][door_name] then
            return door_name
        end

        local door = table.deepcopy(base_prototypes.vertical_entrance_door)
        door.name = door_name
        door.localised_name = {"factorissimo.vertical_factory_entrance_door", tostring(fd.door.size)}

        local ext_half_height = fd.door.size / 2 + 0.5
        door.collision_box = {{-0.5, -ext_half_height}, {0.5, ext_half_height}}
        door.selection_box = {{-0.5, -ext_half_height}, {0.5, ext_half_height}}
        data:extend({door})
        return door.name
    end

    function M.create_door(fd)
        M.check_door(fd)

        local sides = fd.door.side
        local last_name = ""

        -- Проходим по всем сторонам, чтобы убедиться, что прототипы созданы
        -- (Например, если у нас {"s", "e"}, создадутся и горизонтальная, и вертикальная сущности)
        for _, side in ipairs(sides) do
            if side == "w" or side == "e" then
                last_name = M.create_vertical_door(fd)
            else
                last_name = M.create_horizontal_door(fd)
            end
        end
        
        -- Возвращаем имя последней созданной, 
        -- хотя для логики создания фабрик это теперь не критично
        return last_name
    end
end

return M