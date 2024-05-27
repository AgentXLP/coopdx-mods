-- name: Pos Display
-- description: Pos Display\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod renders your coordinates to the screen.
-- pausable: true

local djui_hud_set_resolution,djui_hud_set_font,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,djui_hud_measure_text,djui_hud_render_rect,djui_hud_print_text,math_floor = djui_hud_set_resolution,djui_hud_set_font,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,djui_hud_measure_text,djui_hud_render_rect,djui_hud_print_text,math.floor

local function on_hud_render_behind()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local x = djui_hud_get_screen_width() * 0.84
    local y = djui_hud_get_screen_height() * 0.5

    djui_hud_set_color(0, 0, 0, 127)
    djui_hud_render_rect(x - 10, y + 1, djui_hud_measure_text("x: 000") + 3, 35)
    djui_hud_set_color(255, 255, 255, 255)
    local pos = gMarioStates[0].pos
    y = y - 1
    djui_hud_print_text("x: " .. math_floor(pos.x), x - 7, y, 0.5)
    djui_hud_print_text("y: " .. math_floor(pos.y), x - 7, y + 10, 0.5)
    djui_hud_print_text("z: " .. math_floor(pos.z), x - 7, y + 21, 0.5)
end

hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)