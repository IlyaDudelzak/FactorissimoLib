local M = {}

function M.check_door(fd)
    if not fd.door then
        error("Door data must be defined for factory: " .. tostring(fd.name))
    end
    local door = fd.door
    if door.side == nil then
        error("Outside door side must be defined for factory: " .. tostring(fd.name))
    end
    
    local sides = type(door.side) == "table" and door.side or {door.side}
    local valid_sides = {n = true, e = true, s = true, w = true}
    
    for _, side in ipairs(sides) do
        if not valid_sides[side] then
            error("Outside door side must be one of 'n', 'e', 's', 'w'. Got: " .. tostring(side))
        end
    end
end

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    -- Создает специфический прототип для конкретной стороны
    function M.create_specific_door(fd, side)
        local is_vertical = (side == "w" or side == "e")
        -- Имя теперь максимально простое: factory-entrance-door-2-s
        local door_name = "factory-entrance-door-" .. tostring(fd.door.size) .. "-" .. side
        
        if data.raw["simple-entity-with-force"] and data.raw["simple-entity-with-force"][door_name] then
            return door_name
        end

        -- Выбираем базовый прототип только для получения графики/звуков, имя перезаписываем
        local base = is_vertical and base_prototypes.vertical_entrance_door or base_prototypes.horizontal_entrance_door
        local door = table.deepcopy(base)
        
        door.name = door_name
        -- Локализация: "[Южная] входная дверь завода (2)"
        door.localised_name = {"", "[", {"factorissimo.side_name." .. side}, "] ", {"factorissimo.factory_entrance_door", tostring(fd.door.size)}}

        local half_size = fd.door.size / 2 + 0.5
        if is_vertical then
            door.collision_box = {{-0.5, -half_size}, {0.5, half_size}}
            door.selection_box = {{-0.5, -half_size}, {0.5, half_size}}
        else
            door.collision_box = {{-half_size, -0.5}, {half_size, 0.5}}
            door.selection_box = {{-half_size, -0.5}, {half_size, 0.5}}
        end
        
        data:extend({door})
        return door_name
    end

    function M.create_door(fd)
        M.check_door(fd)
        local sides = type(fd.door.side) == "table" and fd.door.side or {fd.door.side}
        local last_name = ""
        for _, side in ipairs(sides) do
            last_name = M.create_specific_door(fd, side)
        end
        return last_name
    end
end

return M