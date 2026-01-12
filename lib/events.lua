local events = {}
local delayed_functions = {}

factorissimo.on_event = function(event, f)
    for _, e in pairs(type(event) == "table" and event or {event}) do
        local key = tostring(e)
        events[key] = events[key] or {}
        table.insert(events[key], f)
    end
end

factorissimo.on_nth_tick = function(tick, f)
    local key = tostring(tick)
    events[key] = events[key] or {}
    table.insert(events[key], f)
end

local function one_function_from_many(functions)
    local l = #functions
    if l == 1 then return functions[1] end
    return function(arg)
        for i = 1, l do functions[i](arg) end
    end
end

factorissimo.finalize_events = function()
    local i = 0
    for event, functions in pairs(events) do
        local f = one_function_from_many(functions)
        if tonumber(event) and not defines.events[event] then
            script.on_nth_tick(tonumber(event), f)
        elseif event == "ON INIT EVENT" then
            script.on_init(f)
            script.on_configuration_changed(f)
        else
            script.on_event(tonumber(event) or event, f)
        end
        i = i + 1
    end
    log("Finalized " .. i .. " events for " .. script.mod_name)
end

-- Delayed functions logic
factorissimo.execute_later = function(function_key, ticks, ...)
    local marked_for_death = rendering.draw_line {
        color = {0, 0, 0, 0}, width = 0, from = {0, 0}, to = {0, 0},
        surface = "nauvis", time_to_live = ticks
    }
    storage._delayed_functions = storage._delayed_functions or {}
    storage._delayed_functions[script.register_on_object_destroyed(marked_for_death)] = {function_key, {...}}
end

factorissimo.on_event(defines.events.on_object_destroyed, function(event)
    if not storage._delayed_functions then return end
    local data = storage._delayed_functions[event.registration_number]
    if not data then return end
    storage._delayed_functions[event.registration_number] = nil
    local f = delayed_functions[data[1]]
    if f then f(table.unpack(data[2])) end
end)

factorissimo.register_delayed_function = function(key, func)
    delayed_functions[key] = func
end

-- Sentinel Groups
factorissimo.events = {
    on_built = function() return {defines.events.on_built_entity, defines.events.on_robot_built_entity, defines.events.script_raised_built, defines.events.script_raised_revive, defines.events.on_space_platform_built_entity, defines.events.on_biter_base_built} end,
    on_destroyed = function() return {defines.events.on_player_mined_entity, defines.events.on_robot_mined_entity, defines.events.on_entity_died, defines.events.script_raised_destroy, defines.events.on_space_platform_mined_entity} end,
    on_built_tile = function() return {defines.events.on_robot_built_tile, defines.events.on_player_built_tile, defines.events.on_space_platform_built_tile} end,
    on_mined_tile = function() return {defines.events.on_player_mined_tile, defines.events.on_robot_mined_tile, defines.events.on_space_platform_mined_tile} end,
    on_init = function() return "ON INIT EVENT" end
}