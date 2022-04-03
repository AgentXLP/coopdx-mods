function on_hud_render()
    if gun == nil or pause == true then
        return
    end

    -- set text and scale
    local text = tostring(gPlayerSyncTable[0].ammo) .. "/" .. tostring(gGlobalSyncTable.maxAmmo)

    -- render to native screen space, with the MENU font
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_HUD)

    -- get height of screen and text
    local screenHeight = djui_hud_get_screen_height()

    local x = 10
    local y = screenHeight - 35

    -- set color and render
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("AMMO", x, y - 20, 1)
    djui_hud_print_text(text, x, y, 1)
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)