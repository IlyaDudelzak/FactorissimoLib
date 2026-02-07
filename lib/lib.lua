_G.factorissimo = factorissimo or {["factory"] = {}}
_G.F = "__FactorissimoLib__"

require "lib.table"
require "lib.string"
require "lib.defines"
require "lib.colors"
require "lib.factory.lib"
require "lib.metadata"
require "lib.alternatives"
require "lib.common"
require "lib.prototype-table"

factorissimo.print_logging = true


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

if data and data.raw and not data.raw.item["iron-plate"] then
    factorissimo.stage = "settings"
elseif data and data.raw then
    factorissimo.log = function (message)
        if(factorissimo.print_logging) then
            log(message)
        end
    end
    factorissimo.stage = "data"
elseif script then
    factorissimo.log = function (message)
        if(factorissimo.print_logging) then
            game.print(message)
        end
    end
    factorissimo.stage = "control"
    require "control-stage"
else
    error("Could not determine load order stage.")
end
