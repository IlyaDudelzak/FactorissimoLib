-- script/overlay.lua

local Overlay = {}

local sprite_path_translation = {
    virtual = "virtual-signal",
}

local function draw_overlay_sprite(signal, target_entity, offset, scale, id_table)
    -- В 2.0 signal.type может быть nil, если это предмет
    local type_path = sprite_path_translation[signal.type] or signal.type or "item"
    local sprite_name = type_path .. "/" .. signal.name
    
    if target_entity.valid then
        local sprite_data = {
            sprite = sprite_name,
            x_scale = scale,
            y_scale = scale,
            target = {
                entity = target_entity,
                offset = offset,
            },
            surface = target_entity.surface,
            only_in_alt_mode = true,
            render_layer = "entity-info-icon",
        }
        -- Рисуем тени (fake shadows) для читаемости
        local shadow_radius = 0.07 * scale
        for _, shadow_offset in pairs {{0, shadow_radius}, {0, -shadow_radius}, {shadow_radius, 0}, {-shadow_radius, 0}} do
            sprite_data.tint = {0, 0, 0, 0.5} 
            sprite_data.target.offset = {offset[1] + shadow_offset[1], offset[2] + shadow_offset[2]}
            table.insert(id_table, rendering.draw_sprite(sprite_data).id)
        end
        -- Рисуем саму иконку
        sprite_data.tint = nil
        sprite_data.target.offset = offset
        table.insert(id_table, rendering.draw_sprite(sprite_data).id)

        -- Поддержка иконок качества (Space Age)
        local quality = signal.quality and prototypes.quality[signal.quality]
        if quality and not quality.hidden and quality.level > 0 then
            table.insert(id_table, rendering.draw_sprite {
                sprite = "quality/" .. quality.name,
                target = {
                    entity = target_entity,
                    offset = {offset[1] - 0.25 * scale, offset[2] + 0.25 * scale},
                },
                surface = target_entity.surface,
                only_in_alt_mode = true,
                render_layer = "entity-info-icon",
                x_scale = scale * 0.4,
                y_scale = scale * 0.4,
            }.id)
        end
    end
end

-- Логика распределения иконок в прямоугольнике
local function get_nice_arrangement(width, height, amount)
    if amount <= 0 then return {} end
    local opt_rows, opt_cols, opt_scale = 1, 1, 0
    for rows = 1, math.ceil(math.sqrt(amount)) do
        local cols = math.ceil(amount / rows)
        local scale = math.min(width / cols, height / rows)
        if scale > opt_scale then
            opt_rows, opt_cols, opt_scale = rows, cols, scale
        end
    end
    opt_scale = (opt_scale ^ 0.8) * (1.5 ^ (0.8 - 1))
    local result = {}
    for i = 0, amount - 1 do
        local col = i % opt_cols
        local row = math.floor(i / opt_cols)
        local cols_in_row = (row < opt_rows - 1 and opt_cols or (amount - 1) % opt_cols + 1)
        table.insert(result, {
            x = (2 * col + 1 - cols_in_row) * width / (2 * opt_cols),
            y = (2 * row + 1 - opt_rows) * height / (2 * opt_rows),
            scale = opt_scale
        })
    end
    return result
end

-- Обновление отображения на фасаде
function factorissimo.update_overlay(factory, draw_onto)
    if not factory.outside_overlay_displays then factory.outside_overlay_displays = {} end
    
    -- Очистка старых спрайтов
    if not draw_onto then
        for _, id in pairs(factory.outside_overlay_displays) do
            local object = rendering.get_object_by_id(id)
            if object then object.destroy() end
        end
        factory.outside_overlay_displays = {}
    end

    if not (factory.building and factory.building.valid) then return end
    local controller = factory.inside_overlay_controller
    if not (controller and controller.valid) then return end
    
    local cb = controller.get_or_create_control_behavior()
    if not cb or (cb.enabled == false) then return end

    -- Извлекаем иконки из всех логистических секций (2.0)
    local overlay_icons = {}
    for _, section in pairs(cb.sections) do
        if section.active then
            for _, filter in pairs(section.filters) do
                if filter.value and filter.value.name then
                    table.insert(overlay_icons, filter.value)
                end
            end
        end
    end

    if #overlay_icons == 0 then return end

    local layout_ov = factory.layout.overlays
    local positions = get_nice_arrangement(layout_ov.outside_w, layout_ov.outside_h, #overlay_icons)
    
    for i, param in ipairs(overlay_icons) do
        draw_overlay_sprite(
            param,
            draw_onto or factory.building,
            {positions[i].x + layout_ov.outside_x, positions[i].y + layout_ov.outside_y},
            positions[i].scale,
            factory.outside_overlay_displays
        )
    end
end

-- Функция апгрейда (создание контроллера внутри)
function factorissimo.build_display_upgrade(factory)
    if not factory.force.technologies["factory-interior-upgrade-display"].researched then return end
    if factory.inside_overlay_controller and factory.inside_overlay_controller.valid then return end
    
    local pos = factory.layout.overlays
    local rotated_position = factorissimo.rotate_pos(factorissimo.add_pos(factory.inside_pos, pos.inside_pos), factory.layout.door_side)
    local controller = factory.inside_surface.create_entity {
        name = "factory-overlay-controller",
        position = rotated_position,
        force = factory.force,
        quality = factory.quality
    }
    controller.minable = false
    controller.destructible = false
    controller.rotatable = false
    factory.inside_overlay_controller = controller
end

return Overlay