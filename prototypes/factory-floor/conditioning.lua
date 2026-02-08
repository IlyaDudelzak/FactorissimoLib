local M = {}

local base_prototypes = require("lib.base-prototypes")

function M.create_conditioning_process(surface_name)
    local conditioning_process = table.deepcopy(base_prototypes.air_conditioning_process)
    conditioning_process.name = conditioning_process.name .. surface_name

    data:extend({conditioning_process})
end


return M