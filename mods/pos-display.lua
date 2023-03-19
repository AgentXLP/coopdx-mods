-- name: Pos Display
-- description: Pos Display\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod renders your coordinates to the screen.

local djui_hud_set_resolution = djui_hud_set_resolution
local djui_hud_set_font = djui_hud_set_font
local djui_hud_get_screen_width = djui_hud_get_screen_width
local djui_hud_get_screen_height = djui_hud_get_screen_height
local djui_hud_set_color = djui_hud_set_color
local djui_hud_render_rect = djui_hud_render_rect
local djui_hud_print_text = djui_hud_print_text

local function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local x = djui_hud_get_screen_width() * 0.84
    local y = djui_hud_get_screen_height() * 0.5

    djui_hud_set_color(0, 0, 0, 127)
    djui_hud_render_rect(x - 10, y + 1, djui_hud_measure_text("x: 000") + 3, 35)
    djui_hud_set_color(255, 255, 255, 255)
    local m = gMarioStates[0]
    y = y - 1
    djui_hud_print_text("x: " .. math.floor(m.pos.x), x - 7, y, 0.5)
    djui_hud_print_text("y: " .. math.floor(m.pos.y), x - 7, y + 10, 0.5)
    djui_hud_print_text("z: " .. math.floor(m.pos.z), x - 7, y + 21, 0.5)
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)