-- name: Galaxy Star Select
-- incompatible: star-select
-- description: Galaxy Star Select\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds the Super Mario Galaxy star select screen that replaces the original SM64 one.

LEVEL_STAR_SELECT = level_register("level_star_select_entry", COURSE_NONE, "Star Select", "ss", 28000, 0x28, 0x28, 0x28)

TEX_GRADIENT = get_texture_info("gradient")
TEX_GRADIENT_FLIPPED = get_texture_info("gradient_flipped")
TEX_BACK_BUTTON = get_texture_info("back")

gPaintingPositions = {
    [LEVEL_BOB] = { { x = -5222.4,    y =  409.6,    z = -153.6 } },
    [LEVEL_CCM] = { { x = -2611.2,    y = -307.2,    z = -4352.0 } },
    [LEVEL_WF]  = { { x = -51.2,      y = -204.8,    z = -4505.6 } },
    [LEVEL_JRB] = { { x =  4300.8,    y =  409.6,    z = -537.6 } },
    [LEVEL_LLL] = { { x = -1689.6,    y = -1126.4,   z = -3942.4} },
    [LEVEL_SSL] = { { x = -2611.2,    y = -1177.6,   z = -1075.2 } },
    [LEVEL_HMC] = { { x =  2099.2,    y = -1484.8,   z = -2278.4 } },
    [LEVEL_DDD] = { { x =  3456.0,    y = -1075.2,   z =  1587.2 } },
    [LEVEL_WDW] = { { x = -966.656,   y =  1305.6,   z = -143.36 } },
    [LEVEL_THI] = { { x = -4598.7842, y =  1354.752, z =  3005.44 }, { x = -5614.5918, y = 1510.4, z = -3292.16 } },
    [LEVEL_TTM] = { { x = -546.816,   y =  1356.8,   z =  3813.376} },
    [LEVEL_TTC] = { { x =  0.0,       y =  2713.6,   z =  7232.5122 } },
    [LEVEL_SL]  = { { x =  3179.52,   y =  1408.0,   z = -271.36 } },
}

djui_hud_set_resolution(RESOLUTION_N64)
sStarSelectHUD = {
    active = false, -- has initiated warp to the star select screen, used to determine whether not every mario should be hidden, exists to prevent mario from showing up in the star select for 1 frame
    bottomBarY = djui_hud_get_screen_height(), -- y position of the bottom bar
    topBarY = -64, -- y position of the top bar
    targetLevel = LEVEL_BOB, -- the level to warp to
    stars = { nil, nil, nil, nil, nil, nil }, -- star object table
    timeSinceMovedStick = 0, -- amount of time in frames since the stick was moved and changed the selected star, resets when between when 10 frames have passed
    selectedStar = 1, -- the selected star
    starSelected = false -- has selected a star
}
sDjuiTransition = {
    fadeIn = true,
    fadeAlpha = -1,
    time = -1,
    color = { r = 0, g = 0, b = 0 }
}

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

initStarSelect = false
function update()
    if gNetworkPlayers[0].currLevelNum == LEVEL_STAR_SELECT then
        if not initStarSelect then
            initStarSelect = true
            play_music(0, SEQUENCE_ARGS(4, SEQ_MENU_STAR_SELECT), 0)

            camera_freeze()
            hud_hide()
            vec3f_set(gLakituState.pos, 0, 0, -1000)
            vec3f_set(gLakituState.focus, 0, 0, 1000)

            spawn_non_sync_object(id_bhvGalaxyActSelector, E_MODEL_NONE, 0, 0, 0, nil)
        end

        for i = 0, MAX_PLAYERS - 1 do
            set_mario_action(gMarioStates[i], ACT_DISAPPEARED, 0)
        end
    end
end

--- @param m MarioState
function mario_update(m)
    if sStarSelectHUD.active then
        m.marioBodyState.modelState = 0x100
        m.freeze = 1
    end

    if m.playerIndex ~= 0 then return end

    if ((m.floor ~= nil and m.floor.type >= 0x00D3 and m.floor.type <= 0x00FC) or gNetworkPlayers[0].currAreaIndex == 3 and m.pos.y < -1600) and sDjuiTransition.fadeAlpha < 0 and gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE and m.action == ACT_DISAPPEARED and not is_game_paused() then
        sStarSelectHUD.targetLevel = obj_nearest_painting_level(m.marioObj)
        play_djui_transition(false, 40, 255, 255, 255)
    end
    if sDjuiTransition.fadeAlpha == 255 and not sDjuiTransition.fadeIn and gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE then
        warp_to_level(LEVEL_STAR_SELECT, 1, 0)
        sStarSelectHUD.active = true
        play_djui_transition(true, 17, 255, 255, 255)
    end
end

function on_warp()
    initStarSelect = false

    -- reset
    djui_hud_set_resolution(RESOLUTION_N64)
    sStarSelectHUD.active = false
    sStarSelectHUD.bottomBarY = djui_hud_get_screen_height()
    sStarSelectHUD.topBarY = -64
    sStarSelectHUD.stars = { nil, nil, nil, nil, nil, nil }
    sStarSelectHUD.canSelect = true
    sStarSelectHUD.selectedStar = 1
    sStarSelectHUD.starSelected = false

    camera_unfreeze()
    hud_show()
end

function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local width = djui_hud_get_screen_width()
    local height = djui_hud_get_screen_height()

    if gNetworkPlayers[0].currLevelNum == LEVEL_STAR_SELECT then
        --- @type MarioState
        local m = gMarioStates[0]

        djui_hud_set_color(255, 255, 255, 190)
        local barWidth = djui_hud_get_screen_width() / 60
        djui_hud_render_texture(TEX_GRADIENT_FLIPPED, 0, sStarSelectHUD.topBarY, barWidth, 1)
        djui_hud_render_texture(TEX_GRADIENT, 0, sStarSelectHUD.bottomBarY, barWidth, 1)

        djui_hud_set_color(255, 255, 255, 255)
        if CAP ~= nil then -- hacky beta 31 check
            djui_hud_render_texture(TEX_BACK_BUTTON, 0, sStarSelectHUD.bottomBarY, 0.5, 0.5)
            if (m.controller.buttonPressed & Z_TRIG) ~= 0 and not sStarSelectHUD.starSelected then warp_to_castle(sStarSelectHUD.targetLevel) end
        end

        local name = get_level_name(level_to_course(sStarSelectHUD.targetLevel), sStarSelectHUD.targetLevel, 1)
        djui_hud_print_text(name, (width * 0.5) - (djui_hud_measure_text(name) * 0.5), sStarSelectHUD.topBarY + 12, 1)
        local star = get_star_name(level_to_course(sStarSelectHUD.targetLevel), sStarSelectHUD.selectedStar)
        djui_hud_print_text(star, (width * 0.5) - (djui_hud_measure_text(star) * 0.5 * 0.5), sStarSelectHUD.topBarY + 40, 0.5)

        djui_hud_print_text("Best Score", width - 142, sStarSelectHUD.bottomBarY + 24, 0.5)

        djui_hud_set_font(FONT_HUD)
        djui_hud_render_texture(gMarioStates[0].character.hudHeadTexture, (width * 0.5) - 16, sStarSelectHUD.bottomBarY + 24, 1, 1)
        djui_hud_print_text("x", width * 0.5, sStarSelectHUD.bottomBarY + 24, 1)
        djui_hud_print_text(normalize(hud_get_value(HUD_DISPLAY_LIVES)), (width * 0.5) + 16, sStarSelectHUD.bottomBarY + 24, 1)

        djui_hud_render_texture(gTextures.coin, width - 87, sStarSelectHUD.bottomBarY + 24, 1, 1)
        djui_hud_print_text("x", width - 71, sStarSelectHUD.bottomBarY + 24, 1)
        djui_hud_print_text(normalize(save_file_get_course_coin_score(get_current_save_file_num() - 1, level_to_course(sStarSelectHUD.targetLevel) - 1)), width - 56, sStarSelectHUD.bottomBarY + 24, 1)

        if sDjuiTransition.fadeAlpha < 0 then
            sStarSelectHUD.topBarY = approach_number(sStarSelectHUD.topBarY, 0, 8, 8)
            sStarSelectHUD.bottomBarY = approach_number(sStarSelectHUD.bottomBarY, height - 64, 8, 8)
        elseif sStarSelectHUD.starSelected then
            sStarSelectHUD.topBarY = approach_number(sStarSelectHUD.topBarY, -64, 8, 8)
            sStarSelectHUD.bottomBarY = approach_number(sStarSelectHUD.bottomBarY, djui_hud_get_screen_height(), 8, 8)
        end
    end

    update_djui_transitions()
end

smlua_audio_utils_replace_sequence(SEQ_MENU_STAR_SELECT, 26, 127, "star_select")

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)