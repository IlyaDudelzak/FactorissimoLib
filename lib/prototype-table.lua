local M = {}
local metadata = require("__FactorissimoLib__/lib/metadata")

M.bank_type = "item"
M.bank_suffix = "-data-bank"

if data then
    local base_prototypes = require("__FactorissimoLib__/lib/base-prototypes")

    function M.exists(name)
        if not data.raw[M.bank_type] then 
            return false 
        end
        if not data.raw[M.bank_type][name .. M.bank_suffix] then
            return false
        end
        if not metadata.decode_metadata(data.raw[M.bank_type][name .. M.bank_suffix]) then
            return false
        end
        return true
    end

    function error_if_not_exists(name)
        if not data.raw[M.bank_type] then 
            error("No item-request prototypes found.")
        end
        if not data.raw[M.bank_type][name .. M.bank_suffix] then
            error("No item-request prototype found for name: " .. name)
        end
        if not metadata.decode_metadata(data.raw[M.bank_type][name .. M.bank_suffix]) then
            error("Failed to decode metadata for item-request prototype: " .. name)
        end
        return true 
    end

    function M.create(name)
        local prototype = table.deepcopy(base_prototypes.data_bank)
        prototype.name = name .. M.bank_suffix
        metadata.encode_metadata({}, prototype)
        data:extend({prototype})
        return prototype
    end

    function M.set(name, data_table)
        local prototype = data.raw[M.bank_type][name .. M.bank_suffix]
        if not prototype then error("Prototype bank " .. name .. " not found.") end
        
        metadata.encode_metadata(data_table, prototype)
        data.raw[M.bank_type][name .. M.bank_suffix] = prototype
        return prototype
    end

    function M.add(name, key_or_value, value)
        local prototype = data.raw[M.bank_type][name .. M.bank_suffix]
        if not prototype then error("Prototype bank " .. name .. " not found.") end
        
        local data_table = metadata.decode_metadata(prototype) or {}
        
        if value ~= nil then
            data_table[key_or_value] = value
        else
            table.insert(data_table, key_or_value)
        end
        
        metadata.encode_metadata(data_table, prototype)
        data.raw[M.bank_type][name .. M.bank_suffix] = prototype

        return prototype
    end
    
    function M.get_table(name)
        error_if_not_exists(name)
        local prototype = data.raw[M.bank_type][name .. M.bank_suffix]
        return metadata.decode_metadata(prototype)
    end
else
    function M.exists(name)
        local success, bank = pcall(function() return prototypes[M.bank_type] end)
        if not success or not bank then 
            return false
        end
        local object = bank[name .. M.bank_suffix]
        if not object then
            return false
        end
        if not metadata.decode_metadata(object) then
            return false
        end
        return true
    end

    function error_if_not_exists(name)
        if not prototypes[M.bank_type] then 
            error("No item-request prototypes found.")
        end
        if not prototypes[M.bank_type][name .. M.bank_suffix] then
            error("No item-request prototype found for name: " .. name)
        end
        if not metadata.decode_metadata(prototypes[M.bank_type][name .. M.bank_suffix]) then
            error("Failed to decode metadata for item-request prototype: " .. name)
        end
        return true 
    end

    function M.get_table(name)
        error_if_not_exists(name)
        local prototype = prototypes[M.bank_type][name .. M.bank_suffix]
        return metadata.decode_metadata(prototype)
    end
end

return M