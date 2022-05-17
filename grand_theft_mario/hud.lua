showTitle = true
function on_hud_render()
    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil then
        return
    end
    local localGun = gPlayerSyncTable[0].gun
    if firstPerson == false then
        if gun == nil then return end
        -- set text
        local text = tostring(get_ammo(gMarioStates[0])) .. "/" .. tostring(gunTable[localGun].maxAmmo)

        -- render to native screen space
        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_font(FONT_HUD)

        local x = 10
        local y = djui_hud_get_screen_height() - 35

        -- set color and render
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("AMMO", x, y - 20, 1)
        djui_hud_print_text(text, x, y, 1)
    else
        local m = gMarioStates[0]

        local multiplier = 8
        if m.health >= 2048 then
            multiplier = 8
        elseif m.health >= 1792 and m.health < 2048 then
            multiplier = 7
        elseif m.health >= 1536 and m.health < 1792 then
            multiplier = 6
        elseif m.health >= 1280 and m.health < 1536 then
            multiplier = 5
        elseif m.health >= 1024 and m.health < 1280 then
            multiplier = 4
        elseif m.health >= 768 and m.health < 1024 then
            multiplier = 3
        elseif m.health >= 512 and m.health < 768 then
            multiplier = 2
        elseif m.health >= 256 and m.health < 512 then
            multiplier = 1
        elseif m.health >= 0 and m.health < 256 then
            multiplier = 0
        end
        local health = math.floor((100 / 8) * multiplier)

        -- render to native screen space
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_NORMAL)

        local width = djui_hud_get_screen_width()
        local y = djui_hud_get_screen_height() - 140

        djui_hud_set_color(255, 255, 0, 128)
        djui_hud_render_texture(get_texture_info("crosshair"), djui_hud_get_screen_width() * 0.5 - 15, djui_hud_get_screen_height() * 0.5 - 5, 2, 2)

        if gNetworkPlayers[0].currLevelNum ~= LEVEL_SA then
            -- set color and render
            djui_hud_set_color(0, 0, 0, 128)
            djui_hud_render_rect(15, y, 300, 120)

            if health < 20 then
                djui_hud_set_color(255, 0, 0, 255)
            else
                djui_hud_set_color(255, 255, 0, 255)
            end
            djui_hud_print_text("HEALTH", 25, y + 80, 1)
            djui_hud_print_text(tostring(health), 138, y + 10, 3.75)

            if (m.flags & MARIO_METAL_CAP) ~= 0 or (m.flags & MARIO_VANISH_CAP) ~= 0 then
                djui_hud_set_color(0, 0, 0, 128)
                djui_hud_render_rect(330, y, 300, 120)

                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("SUIT", 340, y + 80, 1)
                djui_hud_print_text("200", 440, y + 10, 3.75)

                gPlayerSyncTable[0].metalCap = true
            else
                gPlayerSyncTable[0].metalCap = false
            end

            if gun ~= nil then
                djui_hud_set_color(0, 0, 0, 128)
                djui_hud_render_rect(width - 315, y, 300, 120)
                djui_hud_set_color(255, 255, 0, 255)
                djui_hud_print_text("AMMO", width - 305, y + 80, 1)
                djui_hud_print_text(tostring(get_ammo(gMarioStates[0])), width - 240, y + 10, 3.75)
                djui_hud_print_text(tostring(gunTable[localGun].maxAmmo), width - 75, y + 80, 1)
            end
        else
            djui_hud_set_color(255, 160, 0, 120)
            if health <= 25 then
                djui_hud_set_color(255, 0, 0, 120)
            end
            djui_hud_render_texture(get_texture_info("health"), 5, y + 70, 1.70, 1.75)
            djui_hud_print_text(tostring(health), 65, y + 70, 2)
            djui_hud_set_color(255, 160, 0, 120)
            djui_hud_render_texture(get_texture_info("suit"), 175, y + 70, 1.75, 1.75)
            djui_hud_print_text("|", 155, y + 70, 2)
            local bhDisplay = bhGain - 1
            bhDisplay = math.floor(bhDisplay * 100)
            djui_hud_print_text(tostring(bhDisplay), 250, y + 70, 2)

            if gun ~= nil then
                djui_hud_print_text(tostring(get_ammo(gMarioStates[0])) .. "|" .. tostring(gunTable[localGun].maxAmmo), width - 150, y + 70, 2)
            end
        end

        if m.health <= 0xff then
            djui_hud_set_color(255, 0, 0, 100)
            djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
            m.forwardVel = 0
            m.vel.x = 0
            m.vel.z = 0
        end
    end

    if showTitle and gNetworkPlayers[0].currLevelNum == LEVEL_SA then
        local m = gMarioStates[0]
        set_mario_action(m, ACT_FREEFALL, 0)
        m.health = 0x880
        m.pos.x = 2240
        m.pos.y = -710
        m.pos.z = -968

        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_render_texture(get_texture_info("title"), 0, -10, djui_hud_get_screen_width() / 512, djui_hud_get_screen_height() / 512 + 0.05)

        djui_hud_set_font(FONT_NORMAL)
        djui_hud_set_color(244, 117, 12, 255)
        djui_hud_print_text("HALF-LIFE", 10, djui_hud_get_screen_height() - 45, 1)
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("New Game [A]", 10, djui_hud_get_screen_height() - 250, 1)
        djui_hud_print_text("Quit [Z]", 10, djui_hud_get_screen_height() - 120, 1)

        if (m.controller.buttonPressed & A_BUTTON) ~= 0 or (m.controller.buttonPressed & B_BUTTON) ~= 0 then
            showTitle = false
            -- on_gordon_command("on")
            on_fp_command("on")
        elseif (m.controller.buttonPressed & Z_TRIG) ~= 0 then
            warp(LEVEL_CASTLE_GROUNDS, 1)
            showTitle = false
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)