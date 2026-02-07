
function factorissimo.add_pos(...)
    local positions = {...}
    local result = {x = 0, y = 0}

    for _, pos in ipairs(positions) do
        if not pos or not pos.x or not pos.y then
            error("Position " .. _ .. " is not valid. Expected table with x and y fields.")
        end
        result.x = result.x + pos.x
        result.y = result.y + pos.y
    end

    return result
end

function factorissimo.rotate_pos(a, b, c)
    local x = 0
    local y = 0
    local side = "n"

    if c then 
        x = a
        y = b
        side = c
    else
        x = a.x
        y = a.y
        side = b
    end
    
    if side == "s" then return {x = x, y = y} end
    if side == "n" then return {x = -x - 1, y = -y - 1} end
    if side == "e" then return {x = y, y = -x - 1} end
    if side == "w" then return {x = -y - 1, y = x} end
    return {x = x, y = y}
end

function factorissimo.invert_pos(pos)
    return {x = -pos.x, y = -pos.y}
end