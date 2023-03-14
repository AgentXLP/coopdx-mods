-- name: Flying Gorilla
-- incompatible: romhack
-- description: Flying Gorilla\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds an endless mobile game like obstacle avoiding game to sm64ex-coop based solely off of https://www.youtube.com/shorts/yW8V--TrlJM (hey guys its me flying gorilla)

OFFSET_SPEED = 70

TEX_AD = get_texture_info("ad")

gameTimer = 0
adCooldown = 0
pieceCounter = -2

function restart_level()
    gameTimer = 0
    pieceCounter = -2
    gPlayerSyncTable[0].score = 0
    warp_to_level(LEVEL_BOB, 1, gNetworkPlayers[0].globalIndex)
end

--- @param m MarioState
function act_flying_gorilla(m)
    local areaTimer = get_network_area_timer()

    m.forwardVel = 40
    m.vel.y = 0
    if areaTimer % 2 == 0 then
        spawn_non_sync_object(
            id_bhvMistParticleSpawner,
            E_MODEL_MIST,
            m.pos.x - (sins(m.faceAngle.y) * 70), m.pos.y - 20, m.pos.z - (coss(m.faceAngle.y) * 70),
            nil
        )
    end
    m.marioBodyState.handState = MARIO_HAND_OPEN
    set_mario_animation(m, MARIO_ANIM_WING_CAP_FLY)
    play_sound(SOUND_MOVING_FLYING, m.marioObj.header.gfx.cameraToObject)
    adjust_sound_for_speed(m)

    if m.actionTimer == 0 then
        local result = perform_air_step(m, 0)
        local nan = tostring(m.pos.x) == "nan"
        if result == AIR_STEP_HIT_WALL or result == AIR_STEP_LANDED or nan then
            -- uh oh! stinky!
            if nan then
                init_single_mario(m)
                m.action = ACT_FLYING_GORILLA
                vec3f_copy(m.pos, m.marioObj.header.gfx.prevPos)
            end
            spawn_non_sync_object(id_bhvExplosion, E_MODEL_EXPLOSION, m.pos.x, m.pos.y, m.pos.z, nil)
            m.actionTimer = 1000
            m.health = 0xff
            level_trigger_warp(m, WARP_OP_DEATH)
        end
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
        camera_unfreeze()
        if areaTimer % 30 == 0 and m.playerIndex == 0 then
            gPlayerSyncTable[0].score = gPlayerSyncTable[0].score + 1
        end
    else
        if m.actionTimer > 0 then
            m.actionTimer = m.actionTimer - 1
            if m.actionTimer == 0 then
                m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
                restart_level()
            end
        end
        m.marioObj.header.gfx.node.flags = m.marioObj.header.gfx.node.flags & ~GRAPH_RENDER_ACTIVE
        camera_freeze()
    end

    if m.controller.stickX < 4 and m.controller.stickX > -4 then
        m.actionArg = 0
    end
    if m.controller.stickX < -32 and m.actionArg == 0 then
        local oldActionState = m.actionState
        m.actionState = clamp(m.actionState + 1, 0, 2)
        m.actionArg = 1
        if m.actionState ~= oldActionState then
            play_sound(SOUND_ACTION_FLYING_FAST, m.marioObj.header.gfx.cameraToObject)
        end
    elseif m.controller.stickX > 32 and m.actionArg == 0 then
        local oldActionState = m.actionState
        m.actionState = clamp(m.actionState - 1, 0, 2)
        m.actionArg = 1
        if m.actionState ~= oldActionState then
            play_sound(SOUND_ACTION_FLYING_FAST, m.marioObj.header.gfx.cameraToObject)
        end
    end

    local moveSpeed = 80
    local rotSpeed = 0x600
    switch(m.actionState, {
        [0] = function()
            m.pos.x = approach_number(m.pos.x, -300, moveSpeed, moveSpeed)
            m.faceAngle.z = s16(approach_number(m.faceAngle.z, 0x2000, rotSpeed, rotSpeed))
        end,
        [1] = function()
            m.pos.x = approach_number(m.pos.x, 0, moveSpeed, moveSpeed)
            m.faceAngle.z = s16(approach_number(m.faceAngle.z, 0, rotSpeed, rotSpeed))
        end,
        [2] = function()
            m.pos.x = approach_number(m.pos.x, 300, moveSpeed, moveSpeed)
            m.faceAngle.z = s16(approach_number(m.faceAngle.z, -0x2000, rotSpeed, rotSpeed))
        end
    })
    m.marioObj.header.gfx.angle.z = m.faceAngle.z

    vec3f_set(m.pos, clampf(m.pos.x, -300, 300), m.spawnInfo.startPos.y, m.spawnInfo.startPos.z)
end

ACT_FLYING_GORILLA = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)

function update()
    -- this check is needed for the sake of everything working properly, despite syncing not something this mod has to worry about currently, update runs before the level loads.
    if not gNetworkPlayers[0].currAreaSyncValid then return end

    if gameTimer % 150 == 0 then
        for i = 1, 10 do
            spawn_map_piece()
        end
    end

    gameTimer = gameTimer + 1
end

--- @param m MarioState
function mario_update(m)
    m.numLives = 100
    network_player_set_description(gNetworkPlayers[m.playerIndex], "Score: " .. gPlayerSyncTable[m.playerIndex].score, 255, 255, 255, 255)

    if m.action ~= ACT_FLYING_GORILLA then
        set_mario_action(m, ACT_FLYING_GORILLA, 0)
        m.actionState = 1
    end

    m.flags = m.flags | MARIO_WING_CAP

    if m.playerIndex ~= 0 then return end

    if gNetworkPlayers[0].currLevelNum ~= LEVEL_BOB or gNetworkPlayers[0].currActNum ~= gNetworkPlayers[0].globalIndex then
        restart_level()
    end

    camera_config_enable_free_cam(true)

    if (m.controller.buttonPressed & A_BUTTON) ~= 0 and adCooldown == 0 then
        play_sound(SOUND_MENU_CLICK_FILE_SELECT, m.marioObj.header.gfx.cameraToObject)
        adCooldown = 3600
    end
end

alpha = 255
function on_hud_render()
    if gNetworkPlayers[0].currAreaSyncValid and gMarioStates[0].health > 0xff then
        alpha = approach_number(alpha, 0, 17, 17)
    else
        alpha = approach_number(alpha, 255, 17, 17)
    end

    djui_hud_set_resolution(RESOLUTION_N64)

    local width = djui_hud_get_screen_width()
    local height = djui_hud_get_screen_height()

    if adCooldown > 0 then
        adCooldown = adCooldown - 1
    else
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_render_texture(TEX_AD, (width * 0.5) - 128, height - 72, 1, 1)
    end

    djui_hud_set_resolution(RESOLUTION_DJUI)

    djui_hud_set_color(0, 0, 0, alpha)
    djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_color(255, 255, 255, alpha)

    local text = "Now Loading"

    djui_hud_set_font(FONT_NORMAL)
    djui_hud_print_text(text, (width * 0.5) - (djui_hud_measure_text(text) * 0.5 * 0.5), (height * 0.5) - 20, 0.5)

    djui_hud_set_font(FONT_HUD)
    text = "FLYING GORILLA 64"
    djui_hud_print_text(text, (width * 0.5) - (djui_hud_measure_text(text) * 0.5), height * 0.5, 1)
end

gLevelValues.fixCollisionBugs = 1
gLevelValues.entryLevel = LEVEL_BOB

hud_hide()

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_USE_ACT_SELECT, function() return false end)
hook_event(HOOK_ON_PAUSE_EXIT, function() return false end)
hook_event(HOOK_ON_SCREEN_TRANSITION, function() return false end)

hook_mario_action(ACT_FLYING_GORILLA, act_flying_gorilla, INTERACT_PLAYER)

for i = 0, (MAX_PLAYERS - 1) do
    gPlayerSyncTable[i].score = 0
end