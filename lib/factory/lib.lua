local M = {}
local factories = {}

M.allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

function M.cleanup_name(name)
    if not name then return nil end
    return name:gsub("%-instantiated", ""):gsub("%-starter-pack", "")
    
end

function M.is_factory(name)
    if not name then return false end
    local clean_name = M.cleanup_name(name)
    return factories[clean_name] ~= nil
end

function M.check_factory_data(factory_data)
    if not factory_data then
        error("Invalid factory data: factory_data table is nil")
    elseif not factory_data.type then
        error("Invalid factory data: 'type' field is missing")
    elseif not M.allowed_factory_types[factory_data.type] then
        error("Invalid factory data: 'type' field value '" .. tostring(factory_data.type) .. "' is not allowed")
    elseif not factory_data.name then
        error("Invalid factory data: 'name' field is missing")
    elseif not factory_data.tier then
        error("Invalid factory data: 'tier' field is missing")
    elseif not factory_data.outside_size then
        error("Invalid factory data: 'outside_size' field is missing")
    elseif not factory_data.inside_size then
        error("Invalid factory data: 'inside_size' field is missing")
    elseif not factory_data.color then
        error("Invalid factory data: 'color' field is missing")
    elseif not factory_data.graphics then
        error("Invalid factory data: 'graphics' field is missing")
    end
end

if data then
    local TilesLib = require("__FactorissimoLib__/lib/tiles")
    local FactoryPrototypes = require("__FactorissimoLib__/lib/factory/prototypes")
    function M.add_factory(factory_data)
        M.check_factory_data(factory_data)

        if M.factory_data[factory_data.name] then
            error("Factory with name " .. factory_data.name .. " already exists")
        end

        factory_data.conditioned = factory_data.conditioned or false
        factory_data.pattern = factory_data.pattern or "00"
        factory_data.subgroup = factory_data.subgroup or "factorissimo-factories-tier-" .. factory_data.tier
        
        factory_data.wall_tile_name = TilesLib.createColoredTile("factory-wall", factory_data.color)
        factory_data.floor_tile_name = TilesLib.createColoredTile("factory-floor", factory_data.color)
        if factory_data.type == "factory" then
        elseif factory_data.type == "space-platform-hub" then
        end

        factories[factory_data.name] = factory_data
    end

    function M.make_factory_prototypes(factory_data)
        local prototypes = {}
        local creators = {
            FactoryPrototypes.make_entity,
            FactoryPrototypes.make_item,
            FactoryPrototypes.make_instantiated_item,
            FactoryPrototypes.make_recipe,
            FactoryPrototypes.make_technology
        }
        
        for _, create in ipairs(creators) do
            local p = create(factory_data)
            if p then table.insert(prototypes, p) end
        end

        return prototypes
    end

    function M.addToData()
        local all_prototypes = {}
        for _, factory_data in pairs(M.factory_data) do
            local pros = M.make_factory_prototypes(factory_data)
            for _, p in ipairs(pros) do table.insert(all_prototypes, p) end
        end
        data:extend(all_prototypes)
    end

    function M.get_factory_data(name)
        local clean_name = name:gsub("%-instantiated", "")
        return M.factory_data[clean_name]
    end
else
    local LayoutsLib = require("__FactorissimoLib__/script/factory-layouts")

    for _, prot in pairs(data.raw["storage-tank"]) do
        
    end
end

return M
