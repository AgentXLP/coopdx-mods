showTitle = true
local timer = 0
function on_hud_render()
    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil or is_game_paused() then
        return
    end

    local localWeapon = gPlayerSyncTable[0].weapon

    if gun ~= nil and weaponTable[localWeapon].gun and gNetworkPlayers[0].currLevelNum ~= LEVEL_BM then
        -- set text
        local text = tostring(get_ammo()) .. "/" .. tostring(weaponTable[localWeapon].maxAmmo)

        -- render to native screen space
        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_font(FONT_HUD)

        local x = 10
        local y = djui_hud_get_screen_height() - 35

        -- set color and render
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("AMMO", x, y - 20, 1)
        djui_hud_print_text(text, x, y, 1)
    end

    if sPlayerFirstPerson.enabled then
        local m = gMarioStates[0]

        local multiplier = m.health / 272
        local health = math.floor((100 / 8) * multiplier)

        -- render to native screen space
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_NORMAL)

        local width = djui_hud_get_screen_width()
        local y = djui_hud_get_screen_height() - 140

        djui_hud_set_color(255, 255, 0, 128)
        djui_hud_render_texture(get_texture_info("crosshair"), djui_hud_get_screen_width() * 0.5 - 15, djui_hud_get_screen_height() * 0.5 - 5, 2, 2)

        djui_hud_set_resolution(RESOLUTION_N64)
        djui_hud_set_color(255, 255, 255, 255)
        local x = 70 + (djui_hud_get_screen_width() / 1024) * 250
        local scale = 0.18
        timer = timer + 0.2
        djui_hud_render_texture(get_texture_info(weaponTable[localWeapon].vmodel), x, 58 + 1.4 * math.sin(timer), scale, scale)
        djui_hud_render_texture(get_texture_info(weaponTable[localWeapon].arm), x, 58 + 1.4 * math.sin(timer), scale, scale)
        -- society if you could set djui render order
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_BM then
            djui_hud_render_texture(gTextures.lakitu, djui_hud_get_screen_width() - 38, 205, 1, 1)
            djui_hud_render_texture(gTextures.camera, djui_hud_get_screen_width() - 54, 205, 1, 1)
        end
        djui_hud_set_resolution(RESOLUTION_DJUI)

        if gNetworkPlayers[0].currLevelNum == LEVEL_BM then
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

            if gun ~= nil and weaponTable[localWeapon].gun then
                djui_hud_print_text(tostring(get_ammo()) .. "|" .. tostring(weaponTable[localWeapon].maxAmmo), width - 150, y + 70, 2)
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

    if showTitle and gNetworkPlayers[0].currLevelNum == LEVEL_BM then
        local m = gMarioStates[0]
        set_mario_action(m, ACT_FREEFALL, 0)
        m.health = 0x880
        m.pos.x = 2240
        m.pos.y = -1750
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
            if not sPlayerFirstPerson.enabled then on_fp_command("on") end
        elseif (m.controller.buttonPressed & Z_TRIG) ~= 0 then
            warp(LEVEL_CASTLE_GROUNDS, 1)
            showTitle = false
        end
    end
end

function on_warp()
    if gNetworkPlayers[0].currLevelNum == LEVEL_BM then hud_hide() else hud_show() end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_WARP, on_warp)