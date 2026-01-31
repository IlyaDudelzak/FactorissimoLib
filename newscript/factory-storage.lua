local constants = require("constants")

local function deep_compare(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    for k, v in pairs(t1) do
        if not deep_compare(v, t2[k]) then return false end
    end
    for k, v in pairs(t2) do
        if t1[k] == nil then return false end
    end
    return true
end

function M.cache_factory_data(fd)
    storage.cached_factories = storage.cached_factories or {}
    
    for i, cached_fd in ipairs(storage.cached_factories) do
        if deep_compare(fd, cached_fd) then
            return i
        end
    end
    
    table.insert(storage.cached_factories, fd)
    return #storage.cached_factories
end

function M.get_cached_factories()
    storage.cached_factories = storage.cached_factories or {}
    return storage.cached_factories
end