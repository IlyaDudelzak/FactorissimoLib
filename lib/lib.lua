_G.factorissimo = factorissimo or {}
_G.F = "__FactorissimoLib__"

require "table"
require "string"
require "defines"
require "colors"
require "factory.lib"
require "metadata"
require "alternatives"
require "common"

if data and data.raw and not data.raw.item["iron-plate"] then
    factorissimo.stage = "settings"
elseif data and data.raw then
    factorissimo.stage = "data"
elseif script then
    factorissimo.stage = "control"
    require "control-stage"
else
    error("Could not determine load order stage.")
end
