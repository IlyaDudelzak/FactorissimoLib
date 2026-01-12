local M = {}

M.recursive_tint = function(array, tint)
    for _, v in pairs(array) do
        if type(v) == "table" then
            if v.filename or v.layers or v.stripes then
                v.tint = tint
            end
            M.recursive_tint(v, tint)
        end
    end
    return array
end

M.make_tile_area = function(area, name)
    local result = {}
    local left_top, right_bottom = area[1], area[2]
    for x = left_top[1], right_bottom[1] do
        for y = left_top[2], right_bottom[2] do
            table.insert(result, {position = {x, y}, tile = name})
        end
    end
    return result
end

M.platform_hatch = function(hatch_offset, slice_offset, travel_offset, sky_slice_offset, hatch_illumination_index, spawn, receiving)
    return {
        offset = hatch_offset,
        slice_height = slice_offset or 1,
        sky_slice_height = sky_slice_offset or -1,
        travel_height = travel_offset or 1,
        pod_shadow_offset = {1, 1.3},
        illumination_graphic_index = hatch_illumination_index,
        cargo_unit_entity_to_spawn = spawn or "",
        receiving_cargo_units = receiving or {}
    }
end

M.placeholder_platform_upper_hatch_animation_back = function()
    return {
        layers = {
            util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hatches/platform-upper-hatch-back", {scale = 0.5, shift = {0, -0.5}, frame_count = 20}),
            util.sprite_load("__base__/graphics/entity/cargo-hubs/hatches/shared-upper-hatch-shadow", {scale = 0.5, shift = {4, -0.5}, draw_as_shadow = true, frame_count = 20}),
            util.sprite_load("__base__/graphics/entity/cargo-hubs/hatches/shared-upper-back-hatch-emission", {scale = 0.5, shift = {0, -0.5}, draw_as_glow = true, blend_mode = "additive", frame_count = 20})
        }
    }
end

M.placeholder_platform_upper_hatch_animation_front = function()
    return { layers = { util.sprite_load("__space-age__/graphics/entity/cargo-hubs/hatches/platform-upper-hatch-front", {scale = 0.5, shift = {0, -0.5}, frame_count = 20}) } }
end

return M