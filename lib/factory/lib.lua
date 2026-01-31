local metadata = require("__FactorissimoLib__/lib/metadata")
local prototype_table = require("__FactorissimoLib__/lib/prototype-table")

local M = {}

M.factories = M.factories or {}
M.allowed_factory_types = {["factory"] = 1, ["space-platform-hub"] = 1}

M.GLOBAL_FACTORY_BANK = "factorissimo-global-factory-storage"

function M.prepare_factory_data(factory_data)
    if not factory_data then error("Factory data is nil") end
    local to_delete = {
        "max_health",
        "graphics", 
        "recipe", 
        "technology", 
        "recipe_alternatives", 
        "technology_alternatives"
    }
    for _, f in ipairs(to_delete) do
        factory_data[f] = nil
    end
    return factory_data
end

function M.cleanup_name(name)
    if not name then return nil end
    return name:gsub("%-instantiated", "")
end

function M.is_factory(name)
    local clean_name = M.cleanup_name(name)
    return M.factories[clean_name] ~= nil
end

function M.check_factory_data(factory_data)
    if not factory_data then error("Factory data is nil") end
    local fields = {"type", "name", "tier", "outside_size", "inside_size", "color", "graphics"}
    for _, field in ipairs(fields) do
        if factory_data[field] == nil then
            error("Field '" .. field .. "' is missing in factory: " .. tostring(factory_data.name))
        end
    end
    if not M.allowed_factory_types[factory_data.type] then
        error("Type " .. tostring(factory_data.type) .. " is not allowed")
    end
    if factory_data.inside_size % 2 ~= 0 then
        error("Inside size must be an even number for factory: " .. tostring(factory_data.name))
    end
    if factory_data.outside_size % 2 ~= 0 then
        error("Outside size must be an even number for factory: " .. tostring(factory_data.name))
    end
    if factory_data.inside_size < factory_data.outside_size then
        error("Inside size must be larger or equal than outside size for factory: " .. tostring(factory_data.name))
    end
end

if data then
    local TilesLib = require("__FactorissimoLib__/lib/tiles")
    local EILib = require("__FactorissimoLib__/lib/factory/energy-interfaces")
    local FactoryPrototypes = require("__FactorissimoLib__/lib/factory/prototypes")
    local alternatives = require("__FactorissimoLib__/lib/alternatives")

    prototype_table.create_if_not_exists(M.GLOBAL_FACTORY_BANK)

    function M.add_factory(factory_data)
        M.check_factory_data(factory_data)
        factory_data.mod_name = __name__
        factory_data.conditioned = factory_data.conditioned or false
        factory_data.pattern = factory_data.pattern or "00"
        M.factories[factory_data.name] = factory_data
        prototype_table.add(M.GLOBAL_FACTORY_BANK, factory_data.name, factory_data)
        alternatives.register_category("factory-data-" .. factory_data.name)
    end

    function M.make_factory_prototypes(factory_data)
        factory_data = alternatives.apply_alternatives("factory-data-" .. factory_data.name, factory_data)
        TilesLib.createColoredTile("factory-wall", factory_data.color)
        TilesLib.createColoredTile("factory-floor", factory_data.color)
        EILib.create(factory_data.outside_size)
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
            if p then 
                metadata.encode_metadata(factory_data, p)
                table.insert(prototypes, p) 
            end
        end
        return prototypes
    end

    function M.addToData()
        local all_stored_factories = prototype_table.get_table(M.GLOBAL_FACTORY_BANK)
        if all_stored_factories then
            for name, fd in pairs(all_stored_factories) do
                M.factories[name] = fd
            end
        end
        for _, fd in pairs(M.factories) do
            data:extend(M.make_factory_prototypes(fd))
        end
        data.raw[prototype_table.bank_type][M.GLOBAL_FACTORY_BANK] = nil
    end
else
    local function load_all_factories()
        local types_to_check = {"storage-tank", "space-platform-hub"}
        for _, type_name in ipairs(types_to_check) do
            local protos = prototypes.get_entity_filtered({{filter = "type", type = type_name}})
            for name, prot in pairs(protos) do
                local fd = metadata.decode_metadata(prot)
                if fd then
                    fd.name = name
                    M.factories[name] = fd
                end
            end
        end
    end

    load_all_factories()

    function M.get_factory_data(name)
        local clean = M.cleanup_name(name)
        return M.factories[clean]
    end
end

return M