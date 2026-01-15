local FactoryLib = require("__FactorissimoLib__/lib/factory/lib.lua")
local RemotePrototypeAPI = {}

function RemotePrototypeAPI.add_factory(factory_data)
    return FactoryLib.add_factory(factory_data)
end

function RemotePrototypeAPI.get_factory_data(name)
    return FactoryLib.get_factory_data(name)
end

return RemotePrototypeAPI