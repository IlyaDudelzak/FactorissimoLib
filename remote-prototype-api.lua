local FactoryLib = require("__FactorissimoLib__/lib/factory/lib.lua")
local alternatives = require("__FactorissimoLib__/lib/alternatives")
local M = {}

M.add_factory = FactoryLib.add_factory

M.get_factory_data = FactoryLib.get_factory_data

M.alternatives = {}

M.alternatives.register_category = alternatives.register_category
M.alternatives.add_patch = alternatives.add_patch
M.alternatives.apply_alternatives = alternatives.apply_alternatives

return M