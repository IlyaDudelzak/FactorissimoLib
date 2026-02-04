local M = {}

function M.check_door(fd)
    if not fd.door then
        error("Door data must be defined for factory: " .. tostring(fd.name))
    end

    local door = fd.door

    if door.side == nil then
        error("Outside door side must be defined for factory: " .. tostring(fd.name))
    end
    
    local valid_sides = {n = true, e = true, s = true, w = true}
    if not valid_sides[door.side] then
        error("Outside door side must be one of 'n', 'e', 's', 'w' for factory: " .. tostring(fd.name))
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

        local door = util.deepcopy(base_prototypes.horizontal_entrance_door)
        door.name = door_name
        local ext_half_width = fd.door.size / 2 + 0.5
        door.collision_box = {{-ext_half_width, -0.5}, {ext_half_width, 0.5}}
        
        data:extend({door})
        return door.name
    end

    function M.create_vertical_door(fd)
        local door_name = "vertical-factory-entrance-door-" .. tostring(fd.door.size)
        
        if data.raw["simple-entity-with-force"] and data.raw["simple-entity-with-force"][door_name] then
            return door_name
        end

        local door = util.deepcopy(base_prototypes.vertical_entrance_door)
        door.name = door_name

        local ext_half_height = fd.door.size / 2 + 0.5
        door.collision_box = {{-0.5, -ext_half_height}, {0.5, ext_half_height}}
        
        data:extend({door})
        return door.name
    end

    function M.create_door(fd)
        M.check_door(fd)

        local side = fd.door.side
        if side == "w" or side == "e" then
            return M.create_vertical_door(fd)
        else
            return M.create_horizontal_door(fd)
        end
    end
end

return M