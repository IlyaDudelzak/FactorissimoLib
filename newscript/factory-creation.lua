local FactoryLib = require("__FactorissimoLib__/lib/factory/lib")
local layout_generator = require("__FactorissimoLib__/lib/factory/layout-generator")
local constants = require("constants")
local utility = require("utility")

local M = {}

function M.create_factory(name)
    local factory = {}
    local fd = FactoryLib.get_factory_data(name)
    factory.cached_data_index = utility.cache_factory_data(fd)

    local tiles = layout_generator.make_tiles(fd)

    factory.layout = {
        tiles = tiles
    }

    return factory
end

function M.handle_factory_placed(factory)
end



return M