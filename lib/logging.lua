function factorissimo.log(...)
    local args = {...}
    local output = {}

    for _, arg in ipairs(args) do
        if type(arg) == "table" then
            -- Проверка на сущность (Entity)
            if arg.valid ~= nil then 
                table.insert(output, string.format("[Entity: %s at %s]", 
                    arg.name, 
                    arg.position and string.format("{x=%.2f, y=%.2f}", arg.position.x, arg.position.y) or "unknown pos"
                ))
            
            elseif type(arg.x) == "number" and type(arg.y) == "number" then
                table.insert(output, string.format("{x=%.3f, y=%.3f}", arg.x, arg.y))
            
            else
                table.insert(output, serpent.block(arg))
            end
        else
            table.insert(output, tostring(arg))
        end
    end

    local final_string = table.concat(output, "  |  ")

    if not data and factorissimo.print_logging then game.print(final_string) end
    log(final_string)
end