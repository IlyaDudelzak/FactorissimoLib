local FactoryLib = require("__FactorissimoLib__/lib/factory/lib")
local constants = require("constants")

local M = {}

function M.is_factory(entity)
    if not entity or not entity.valid then return false end
    return FactoryLib.is_factory(entity.name)
end

return M