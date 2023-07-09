-- name: Super Mario 64: The Underworld
-- incompatible: romhack
-- description: Super Mario 64: The Underworld v1.0.1\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nMario is pulled into another land some call The Underworld...\nHe must make his way through this condemned land and help in both the escape of\nhimself and someone he thinks he can trust\nfrom the Underworld.\nThis is a 30 star romhack with a fully custom cutscene system, dialog system and boss fight entirely in Lua created for the sm64ex-coop level competition.\n\nSpecial thanks to \\#005500\\Squishy\\#dcdcdc\\ for the compass textures

STREAM_EARTHQUAKE = audio_stream_load("earthquake.mp3")
STREAM_SRIATS_SSELDNE = audio_stream_load("sriats_sseldne.mp3")

local SOUND_CUSTOM_APPARITION_DIALOG = audio_sample_load("apparition_dialog.mp3")

local TEX_COMPASS_BACK = get_texture_info("compass_back")
local TEX_COMPASS_CAMERA_DIAL = get_texture_info("compass_camera_dial")
local TEX_COMPASS_PLAYER_DIAL = get_texture_info("compass_player_dial")
local TEX_UNDERWORLD_STAR = get_texture_info("underworld_star")

E_MODEL_CASTLE = smlua_model_util_get_id("castle_geo")
E_MODEL_CASTLE_RISING = smlua_model_util_get_id("castle_rising_geo")
E_MODEL_SKY = smlua_model_util_get_id("sky_geo")
E_MODEL_SHADOW = smlua_model_util_get_id("shadow_geo")
E_MODEL_APPARITION = smlua_model_util_get_id("apparition_geo")
E_MODEL_LETTER = smlua_model_util_get_id("letter_geo")
E_MODEL_SOUL_FLAME = smlua_model_util_get_id("soul_flame_geo")
E_MODEL_SOUL_STAR_NOISE = smlua_model_util_get_id("soul_star_noise_geo")
E_MODEL_NOISE = smlua_model_util_get_id("noise_geo")
E_MODEL_ORB = smlua_model_util_get_id("orb_geo")
E_MODEL_NORMAL_STAR = smlua_model_util_get_id("normal_star_geo")
local E_MODEL_LASER = smlua_model_util_get_id("laser_geo")

PACKET_STAR = 0
PACKET_LASER = 1

local TITLE = "Super Mario 64: The Underworld"
local VERSION = "v1.0.1"
STARS = 30

gGlobalSyncTable.castleRisingTimer = 0
gGlobalSyncTable.stars = if_then_else(network_is_server(), mod_storage_get_total_star_count() or 0, 0)
gGlobalSyncTable.laser = gGlobalSyncTable.stars >= STARS
gGlobalSyncTable.level = LEVEL_CASTLE_GROUNDS

gIntroEvent = {
    titleTimer = 0,
    fallTimer = 0
}

flashAlpha = 0
apparition = false
local starSpawned = false
local teleportTimer = -1
local endingTimer = 0
betrayalCutscene = 0

-- localize functions to improve performance
local set_mario_animation,allocate_mario_action,stop_background_music,obj_get_first_with_behavior_id,audio_stream_play,audio_stream_set_looping,audio_stream_set_volume,play_character_sound,spawn_non_sync_object,vec3f_set,vec3f_copy,min,clamp,play_sound,minf,adjust_sound_for_speed,maxf,set_camera_shake_from_hit,check_common_airborne_cancels,obj_set_model_extended,warp_to_level,set_lighting_color,hud_hide,mario_set_forward_vel,find_floor_height,set_mario_action,get_network_area_timer,audio_stream_stop,play_music,obj_mark_for_deletion,play_transition,network_is_server,is_transition_playing,level_trigger_warp,fade_volume_scale,djui_hud_set_resolution,djui_hud_set_render_behind_hud,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,djui_hud_render_rect,djui_hud_set_font,djui_hud_measure_text,djui_hud_print_text,hud_show,hud_render_power_meter,djui_hud_set_rotation,obj_get_nearest_object_with_behavior_id,audio_sample_play,camera_unfreeze,set_override_envfx,network_player_connected_count,spawn_mist_particles,mod_storage_load,mod_storage_save,smlua_text_utils_course_acts_replace = set_mario_animation,allocate_mario_action,stop_background_music,obj_get_first_with_behavior_id,audio_stream_play,audio_stream_set_looping,audio_stream_set_volume,play_character_sound,spawn_non_sync_object,vec3f_set,vec3f_copy,min,clamp,play_sound,minf,adjust_sound_for_speed,maxf,set_camera_shake_from_hit,check_common_airborne_cancels,obj_set_model_extended,warp_to_level,set_lighting_color,hud_hide,mario_set_forward_vel,find_floor_height,set_mario_action,get_network_area_timer,audio_stream_stop,play_music,obj_mark_for_deletion,play_transition,network_is_server,is_transition_playing,level_trigger_warp,fade_volume_scale,djui_hud_set_resolution,djui_hud_set_render_behind_hud,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,djui_hud_render_rect,djui_hud_set_font,djui_hud_measure_text,djui_hud_print_text,hud_show,hud_render_power_meter,djui_hud_set_rotation,obj_get_nearest_object_with_behavior_id,audio_sample_play,camera_unfreeze,set_override_envfx,network_player_connected_count,spawn_mist_particles,mod_storage_load,mod_storage_save,smlua_text_utils_course_acts_replace

--- @param m MarioState
local function act_cutscene(m)
    set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)
    m.marioBodyState.headAngle.x = approach_number(m.marioBodyState.headAngle.x, -3840, 384, 384)
    m.pos.y = m.floorHeight
    m.marioObj.header.gfx.pos.y = m.pos.y
end

ACT_CUTSCENE = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_WATER_OR_TEXT)

--- @param m MarioState
local function act_cutscene_betrayal(m)
    if m.playerIndex ~= 0 then return end

    if m.actionState == 0 then
        if gDialogState.currentLine == 1 then
            stop_background_music(SEQ_LEVEL_UNDERGROUND)
        elseif gDialogState.currentLine == 6 then
            if obj_get_first_with_behavior_id(id_bhvOrb) ~= nil then
                m.actionState = 1
                return
            end

            audio_stream_play(STREAM_SRIATS_SSELDNE, true, 1)
            audio_stream_set_looping(STREAM_SRIATS_SSELDNE, true)
            audio_stream_set_volume(STREAM_SRIATS_SSELDNE, 1)
            play_character_sound(m, CHAR_SOUND_WAAAOOOW)
            spawn_non_sync_object(
                id_bhvOrb,
                E_MODEL_ORB,
                0, -3350, -5596,
                --- @param o Object
                function(o)
                    o.parentObj = get_npc_with_id(1)
                end
            )
            m.actionState = 1
            return
        end

        set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)

        m.marioBodyState.headAngle.x = 0

        vec3f_set(m.pos, 0, -3627, -5295)
        vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
        m.peakHeight = m.pos.y

        m.faceAngle.x = 0
        m.faceAngle.y = 0x8000
        m.faceAngle.z = 0

        vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)
    elseif m.actionState == 1 then
        if m.actionTimer == 200 then
            play_character_sound(m, CHAR_SOUND_WAAAOOOW)
            m.actionState = 2
            m.forwardVel = -70
            m.vel.y = 50
            m.actionTimer = 0
            return
        elseif m.actionTimer == 0 then
            flashAlpha = 255
        end

        set_mario_animation(m, MARIO_ANIM_DROWNING_PART1)

        m.marioBodyState.headAngle.x = approach_number(m.marioBodyState.headAngle.x, 3840, 384, 384)

        vec3f_set(m.pos, 0, -3627 + m.actionTimer, -5295)
        vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
        m.peakHeight = m.pos.y

        m.faceAngle.x = 0
        m.faceAngle.y = 0x8000
        m.faceAngle.z = 0

        vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)

        m.marioObj.header.gfx.angle.y = m.faceAngle.y
        m.actionTimer = min(m.actionTimer + 1, 200)
    elseif m.actionState == 2 then
        if m.pos.y <= m.floorHeight then
            m.health = clamp(m.health, 0x180, 0x280)
            m.pos.y = m.floorHeight
            m.actionState = 3
            gCustomCutscene.timer = 0
            play_character_sound(m, CHAR_SOUND_ATTACKED)
            return
        end

        set_mario_animation(m, MARIO_ANIM_DROWNING_PART2)

        if m.actionTimer % 10 == 0 then
            play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
        end

        m.pos.x = m.pos.x + sins(m.faceAngle.y) * m.forwardVel
        m.pos.y = m.pos.y + m.vel.y
        m.pos.z = m.pos.z + coss(m.faceAngle.y) * m.forwardVel

        m.vel.y = m.vel.y - 1

        m.faceAngle.x = m.faceAngle.x + 0x1000
        m.faceAngle.z = m.faceAngle.z + 0x1000
        m.actionTimer = m.actionTimer + 1
        vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
        vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)
    elseif m.actionState == 3 then
        if gDialogState.currentDialog == nil then
            m.actionState = 4
            gCustomCutscene.timer = 0
            return
        end

        set_mario_animation(m, MARIO_ANIM_FALL_OVER_BACKWARDS)

        m.pos.x = m.pos.x + sins(m.faceAngle.y) * m.forwardVel
        m.pos.z = m.pos.z + coss(m.faceAngle.y) * m.forwardVel

        m.forwardVel = minf(m.forwardVel + 5, 0)
        if m.forwardVel < 0 then
            play_sound(SOUND_MOVING_TERRAIN_SLIDE, m.marioObj.header.gfx.cameraToObject)
            adjust_sound_for_speed(m)
        end
        m.pos.y = m.floorHeight
        m.faceAngle.x = 0
        m.faceAngle.z = 0
        vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
        vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)
    elseif m.actionState == 4 then
        set_mario_animation(m, MARIO_ANIM_FIRST_PERSON)
    end
end

ACT_CUTSCENE_BETRAYAL = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_WATER_OR_TEXT)

--- @param m MarioState
local function act_getting_sucked_in(m)
    set_mario_animation(m, MARIO_ANIM_DROWNING_PART2)
    m.marioObj.header.gfx.animInfo.animFrame = m.marioObj.header.gfx.animInfo.curAnim.loopEnd

    if m.actionTimer == 0 then
        m.vel.y = 100
        play_character_sound(m, CHAR_SOUND_WAAAOOOW)
    end

    m.pos.y = maxf(m.pos.y + m.vel.y, m.floorHeight)
    m.pos.z = approach_number(m.pos.z, -4500, 70, 70)

    m.vel.y = minf(m.vel.y - 3, 120)

    m.faceAngle.x = m.faceAngle.x + 0x1000
    m.faceAngle.y = m.faceAngle.y + 0x1000
    m.faceAngle.z = m.faceAngle.z + 0x1000

    m.actionTimer = m.actionTimer + 1

    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)

    if m.actionTimer % 10 == 0 then
        set_camera_shake_from_hit(SHAKE_MED_DAMAGE)
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end
end

ACT_GETTING_SUCKED_IN = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)

--- @param m MarioState
local function act_falling_spawn(m)
    set_mario_animation(m, MARIO_ANIM_DROWNING_PART2)
    m.marioObj.header.gfx.animInfo.animFrame = m.marioObj.header.gfx.animInfo.curAnim.loopEnd

    m.pos.y = m.pos.y - 120
    m.faceAngle.x = m.faceAngle.x + 0x1000
    m.faceAngle.y = m.faceAngle.y + 0x1000
    m.faceAngle.z = m.faceAngle.z + 0x1000

    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    vec3f_copy(m.marioObj.header.gfx.angle, m.faceAngle)

    check_common_airborne_cancels(m)

    m.actionTimer = m.actionTimer + 1

    if m.actionTimer % 10 == 0 then
        if m.playerIndex == 0 then
            set_camera_shake_from_hit(SHAKE_MED_DAMAGE)
        end
        play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
    end
end

ACT_FALLING_SPAWN = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_FLAG_DIVING)

--- @param m MarioState
local function mario_update(m)
    m.numLives = if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_COURTYARD, 0, 4)

    if m.playerIndex ~= 0 then
        if active_player(m) ~= 0 and gCustomCutscene.playing then
            obj_set_model_extended(m.marioObj, E_MODEL_NONE)
            m.particleFlags = 0
        end
        return
    end

    if m.action == ACT_IDLE and m.actionState == 3 then
        m.actionState = 0
        m.actionTimer = 0
    end

    if gNetworkPlayers[0].currLevelNum ~= gGlobalSyncTable.level and gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_COURTYARD then
        warp_to_level(gGlobalSyncTable.level, 1, 0)
        return
    end

    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        local risingCastle = obj_get_first_with_behavior_id(id_bhvRisingCastle)
        if risingCastle.oAction == 0 then
            reset_lighting_color()
        end

        if gGlobalSyncTable.stars > 0 then
            warp_to_level_global(LEVEL_BOB, 1, 0)
            return
        end

        if gGlobalSyncTable.castleRisingTimer < 300 and gGlobalSyncTable.castleRisingTimer ~= 0 then
            hud_hide()

            m.freeze = 1
            mario_set_forward_vel(m, 0)
            m.health = max(m.health, 0x180)

            if not gCustomCutscene.playing then
                start_custom_cutscene_generic(5800, 10000, 4300, 2000, risingCastle.oPosY + 4000, -1000, 30, true, true)
            end
        elseif gGlobalSyncTable.castleRisingTimer >= 300 and m.action ~= ACT_GETTING_SUCKED_IN then
            end_custom_cutscene()
            local x = 300 * gNetworkPlayers[0].globalIndex
            vec3f_set(m.pos, x, find_floor_height(x, 810, 0), 0)
            set_mario_action(m, ACT_GETTING_SUCKED_IN, 0)
        end

        if m.pos.y < -6000 then
            if gIntroEvent.fallTimer >= 15 then
                warp_to_level_global(LEVEL_BOB, 1, 0)
            end
            gIntroEvent.fallTimer = gIntroEvent.fallTimer + 1
        end
    elseif gNetworkPlayers[0].currLevelNum == LEVEL_BOB then
        tint_lighting_color()

        if m.action == ACT_FALLING_SPAWN then
            local volume = maxf(1 - (get_network_area_timer() / 70), 0)
            if volume == 0 then
                audio_stream_stop(STREAM_SRIATS_SSELDNE)
                play_music(0, SEQUENCE_ARGS(8, SEQ_LEVEL_UNDERGROUND), 30)
            else
                audio_stream_set_volume(STREAM_SRIATS_SSELDNE, volume)
            end
        end

        if gGlobalSyncTable.stars >= STARS and not gGlobalSyncTable.laser then
            betrayalCutscene = 1
        end

        local apparition = get_npc_with_id(1)
        if betrayalCutscene == 1 then
            if gCustomCutsceneBetrayal.fadeTimer <= 100 then
                gMarioStates[0].freeze = 1
            end

            if gCustomCutsceneBetrayal.fadeTimer == 0 then
                obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvDialogTrigger))
                play_transition(WARP_TRANSITION_FADE_INTO_COLOR, 40, 0, 0, 0)
            elseif gCustomCutsceneBetrayal.fadeTimer == 40 then
                -- just in case
                obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvDialogTrigger))

                vec3f_set(m.pos, 0, -3627, -5295)
                vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
                m.peakHeight = m.pos.y
                m.faceAngle.y = 0x8000
                m.marioObj.header.gfx.angle.y = m.faceAngle.y

                if apparition ~= nil then
                    apparition.oPosX = 0
                    apparition.oPosY = -3627
                    apparition.oPosZ = -5500
                end
                play_transition(WARP_TRANSITION_FADE_FROM_COLOR, 40, 0, 0, 0)
            elseif gCustomCutsceneBetrayal.fadeTimer == 50 then
                start_dialog(3, nil, false, true, 0)
                start_custom_cutscene_betrayal(apparition, true)
                set_mario_action(m, ACT_CUTSCENE_BETRAYAL, 0)
                gGlobalSyncTable.laser = true
            end
            gCustomCutsceneBetrayal.fadeTimer = gCustomCutsceneBetrayal.fadeTimer + 1
        else
            gCustomCutsceneBetrayal.fadeTimer = 0
        end

        local spawned = obj_get_first_with_behavior_id(id_bhvStaticObject) ~= nil
        if gGlobalSyncTable.laser then
            if spawned then
                if m.floor ~= nil and m.floor.type == SURFACE_ICE then
                    if teleportTimer < 0 then
                        play_transition(WARP_TRANSITION_FADE_INTO_COLOR, 5, 0, 255, 255)
                        play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
                        play_sound(SOUND_GENERAL_VANISH_SFX, m.marioObj.header.gfx.cameraToObject)
                        set_mario_action(m, ACT_DISAPPEARED, 0)
                        teleportTimer = 0
                    end

                    if teleportTimer >= 0 then
                        teleportTimer = teleportTimer + 1

                        if teleportTimer >= 40 then
                            gGlobalSyncTable.level = LEVEL_CASTLE_COURTYARD
                        end
                    end
                end
            else
                spawn_non_sync_object(
                    id_bhvStaticObject,
                    E_MODEL_LASER,
                    0, 0, 0,
                    --- @param o Object
                    function(o)
                        o.header.gfx.skipInViewCheck = true
                        o.oFaceAnglePitch = 0
                        o.oFaceAngleYaw = 0
                        o.oFaceAngleRoll = 0
                    end
                )
            end
        end
    elseif gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_COURTYARD then
        local apparition = obj_get_first_with_behavior_id(id_bhvApparition)

        if gNetworkPlayers[0].currAreaIndex == 1 then
            tint_lighting_color()
        else
            if gDialogState.currentDialog ~= nil then
                end_dialog()
                end_custom_cutscene()
            end
            reset_lighting_color()
            stop_background_music(SEQ_LEVEL_BOSS_KOOPA_FINAL)
            gGlobalSyncTable.laser = false
            betrayalCutscene = 0

            if not starSpawned and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
                starSpawned = true
                dialog = true
                spawn_non_sync_object(
                    id_bhvGrandStar,
                    E_MODEL_STAR,
                    0, 300, 0,
                    nil
                )
                for _ = 1, 2 do
                    play_sound(SOUND_GENERAL_VOLCANO_EXPLOSION, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                    play_sound(SOUND_GENERAL_BOWSER_BOMB_EXPLOSION, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                    play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                    play_sound(SOUND_GENERAL_EXPLOSION6, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                    play_sound(SOUND_GENERAL_EXPLOSION7, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                end
            end

            m.health = 0x880
            m.healCounter = 0
            m.hurtCounter = 0

            if m.action == ACT_JUMBO_STAR_CUTSCENE  then
                if not is_transition_playing() then
                    level_trigger_warp(m, WARP_OP_CREDITS_END)
                    gGlobalSyncTable.level = LEVEL_CASTLE_GROUNDS
                end

                fade_volume_scale(0, 0, 300)

                endingTimer = endingTimer + 1
                if endingTimer == 270 then
                    warp_to_level_global(LEVEL_CASTLE_GROUNDS, 1, 0)
                end
            end
        end

        if apparition ~= nil and apparition.oAction < 99 then
            if m.health > 0x180 and m.pos.y == m.floorHeight and (m.action & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)) == 0 and m.floor ~= nil and m.floor.type == SURFACE_NOISE_SLIPPERY then
                m.health = m.health - 8
            end
        else
            m.hurtCounter = 0
        end
    end
end

local function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_render_behind_hud(false)

    local width = djui_hud_get_screen_width()
    local height = djui_hud_get_screen_height()

    -- tint
    local risingCastle = obj_get_first_with_behavior_id(id_bhvRisingCastle)
    if (risingCastle ~= nil and risingCastle.oAction == 2) or gNetworkPlayers[0].currLevelNum == LEVEL_BOB then
        djui_hud_set_color(0, 50, 75, if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_BOB, maxf((1 - (get_network_area_timer() / 90)) * 150, 0), 150))
        djui_hud_render_rect(0, 0, width, height)
    end

    -- flash
    flashAlpha = approach_number(flashAlpha, 0, 8.5, 8.5)
    djui_hud_set_color(255, 255, 255, flashAlpha)
    djui_hud_render_rect(0, 0, width, height)

    -- title
    if gIntroEvent.titleTimer <= 180 and gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        gMarioStates[0].freeze = 1
        gMarioStates[0].health = 0x880
        vec3f_copy(gMarioStates[0].pos, gMarioStates[0].spawnInfo.startPos)

        djui_hud_set_font(FONT_TINY)

        local alpha = 0
        if gIntroEvent.titleTimer < 120 then
            alpha = minf(gIntroEvent.titleTimer / 60, 1) * 255
        else
            alpha = maxf(1 - ((gIntroEvent.titleTimer - 120) / 60), 0) * 255
        end

        djui_hud_set_color(0, 0, 0, if_then_else(gIntroEvent.titleTimer < 120, 255, alpha))
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())

        djui_hud_set_resolution(RESOLUTION_N64)

        local scale = 1.5
        local x = djui_hud_get_screen_width() * 0.5 - djui_hud_measure_text(TITLE) * 0.5 * scale
        local y = djui_hud_get_screen_height() * 0.5

        djui_hud_set_color(0, 255, 255, alpha)
        djui_hud_print_text(TITLE, x, y - 16 * scale, scale)
        djui_hud_render_rect(x, y, djui_hud_measure_text(TITLE) * scale, 2)

        djui_hud_set_color(50, 50, 50, alpha)
        djui_hud_print_text(VERSION, 2, djui_hud_get_screen_height() - 8, 0.5)

        gIntroEvent.titleTimer = gIntroEvent.titleTimer + 1
    end

    hud_show()

    if gNetworkPlayers[0].currLevelNum ~= LEVEL_BOB and gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_COURTYARD then return end

    hud_hide()

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_render_behind_hud(true)
    djui_hud_set_font(FONT_TINY)

    width = djui_hud_get_screen_width()
    height = djui_hud_get_screen_height()
    local x = djui_hud_get_screen_width() - 35
    local y = djui_hud_get_screen_height() - 35

    if gNetworkPlayers[0].currLevelNum == LEVEL_BOB and not gCustomCutscene.playing then
        djui_hud_set_color(255, 255, 255, 255)
        hud_render_power_meter(gMarioStates[0].health, width - 64, 0, 64, 64)

        djui_hud_render_texture(TEX_COMPASS_BACK, x, y, 1, 1)

        djui_hud_set_rotation(gLakituState.yaw, 0.5, 0.5)
        djui_hud_render_texture(TEX_COMPASS_CAMERA_DIAL, x, y, 1, 1)

        djui_hud_set_rotation(gMarioStates[0].faceAngle.y, 0.5, 0.5)
        djui_hud_render_texture(TEX_COMPASS_PLAYER_DIAL, x, y, 1, 1)

        djui_hud_set_rotation(0, 0, 0)
        djui_hud_render_texture(TEX_UNDERWORLD_STAR, 4, 5, 1, 1)
        djui_hud_set_font(FONT_HUD)
        djui_hud_print_text("x", 21, 5, 1)
        djui_hud_print_text(tostring(gGlobalSyncTable.stars), 37, 5, 1)

        local star = obj_get_nearest_object_with_behavior_id(gMarioStates[0].marioObj, id_bhvStar)
        if gGlobalSyncTable.stars < STARS and star ~= nil then
            render_hud_radar(gMarioStates[0], star, TEX_UNDERWORLD_STAR, 1, 1, 24, height - 32)
        end
    end

    if gDialogState.currentDialog ~= nil then
        if gDialogState.npc ~= nil and gDialogState.cutscene and not gCustomCutscene.playing then
            start_custom_cutscene_generic(
                gDialogState.npc.oPosX + sins(gDialogState.npc.header.gfx.angle.y) * gDialogState.cutsceneDistToCamera,
                gDialogState.npc.oPosY + 200,
                gDialogState.npc.oPosZ + coss(gDialogState.npc.header.gfx.angle.y) * gDialogState.cutsceneDistToCamera,
                gDialogState.npc.oPosX,
                gDialogState.npc.oPosY + 100,
                gDialogState.npc.oPosZ,
                25,
                false,
                gDialogState.overrideCurrent
            )
        end
        gDialogState.dialogTimer = gDialogState.dialogTimer + 1

        local alphaNormalized = minf(gDialogState.dialogTimer / 15, 1)
        djui_hud_set_color(0, 0, 0, alphaNormalized * 127)
        djui_hud_render_rect(6, height - 55, 200, 50)

        local pos = { x = gLakituState.pos.x + sins(gLakituState.yaw), y = gLakituState.pos.y, z = gLakituState.pos.z + coss(gLakituState.yaw) }
        local starsLeft = STARS - gGlobalSyncTable.stars

        if gDialogState.skip then
            gDialogState.currentLineContents = gDialogState.currentDialog.lines[gDialogState.currentLine]
                :gsub("$CHARNAME", gMarioStates[0].character.name)
                :gsub("$STARS", starsLeft .. " star" .. if_then_else(starsLeft == 1, ".", "s."))
            gDialogState.canProceed = true
        else
            if gDialogState.dialogTimer % gDialogState.currentDialog.speed == 0 then
                if gDialogState.currentChar <= #gDialogState.currentDialog.lines[gDialogState.currentLine] then
                    local char = gDialogState.currentDialog.lines[gDialogState.currentLine]
                        :gsub("$CHARNAME", gMarioStates[0].character.name)
                        :gsub("$STARS", starsLeft .. " star" .. if_then_else(starsLeft == 1, ".", "s."))
                        :sub(gDialogState.currentChar, gDialogState.currentChar)
                    gDialogState.currentLineContents = gDialogState.currentLineContents .. char
                    gDialogState.currentChar = gDialogState.currentChar + 1

                    if char ~= " " then
                        audio_sample_play(SOUND_CUSTOM_APPARITION_DIALOG, pos, 0.8)
                    end
                else
                    gDialogState.canProceed = true
                end
            end
        end

        local splitLines = split_string(gDialogState.currentLineContents, 36)
        if splitLines ~= nil and splitLines[1] ~= nil then
            djui_hud_set_color(255, 255, 255, alphaNormalized * 255)

            if gDialogState.currentDialog.id == 3 and gDialogState.currentLine >= 6 then
                djui_hud_print_text("The Shitilizer", 10, height - 70, 1)
            else
                djui_hud_print_text(gDialogState.currentDialog.name, 10, height - 70, 1)
            end

            if splitLines[2] == nil then
                djui_hud_print_text(gDialogState.currentLineContents, 10, height - 37, 1)
            else
                djui_hud_print_text(splitLines[1], 10, height - 47, 1)
                djui_hud_print_text(splitLines[2], 10, height - 33, 1)
            end
        end

        if gDialogState.canProceed then
            djui_hud_set_color(255, 255, 255, (math.sin(gDialogState.dialogTimer * 0.3) * 127.5) + 127.5)
            djui_hud_print_text("[A]", 185, height - 23, 1)

            if (gMarioStates[0].controller.buttonPressed & (A_BUTTON | B_BUTTON)) ~= 0 then
                play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                if (gMarioStates[0].controller.buttonPressed & B_BUTTON) ~= 0 then
                    audio_sample_play(SOUND_CUSTOM_APPARITION_DIALOG, pos, 0.8)
                    gDialogState.skip = true
                else
                    gDialogState.skip = false
                end

                gDialogState.currentLine = gDialogState.currentLine + 1
                if gDialogState.currentLine > #gDialogState.currentDialog.lines then
                    end_dialog()
                else
                    reset_dialog_line()
                end
            end
        end
    end
end

local function on_level_init()
    gGlobalSyncTable.castleRisingTimer = 0
    musicChanged = false
    lastNpcId = 0
    endingTimer = 0
end

local function on_warp()
    camera_unfreeze()
    set_override_envfx(-1)
    end_custom_cutscene()
    end_dialog()

    if gNetworkPlayers[0].currLevelNum == LEVEL_BOB then
        set_mario_action(gMarioStates[0], ACT_FALLING_SPAWN, 0)
    elseif gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_COURTYARD then
        if apparition then
            if network_player_connected_count() > 1 then
                vec3f_set(gMarioStates[0].pos, 0, 0, 0)
            else
                vec3f_set(gMarioStates[0].pos, 0, 0, 1000)
            end
        end
    end

    apparition = false

    audio_stream_stop(STREAM_EARTHQUAKE)
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_BOB then
        audio_stream_stop(STREAM_SRIATS_SSELDNE)
    end

    musicChanged = false
    teleportTimer = -1
    starSpawned = false
end

function on_sync_valid()
    for_each_object_with_behavior(id_bhvStar, soul_star)
end

--- @param m MarioState
local function on_player_disconnected(m)
    local apparition = obj_get_first_with_behavior_id(id_bhvApparition)
    if apparition ~= nil and apparition.oNpcTalkingTo == gNetworkPlayers[m.playerIndex].globalIndex and apparition.oDialogId == 5 then
        apparition.oAction = 100
        network_send_object(apparition, true)
    end
end

--- @param m MarioState
--- @param o Object
local function allow_interact(m, o)
    if gNetworkPlayers[m.playerIndex].currLevelNum == LEVEL_CASTLE_COURTYARD then
        if o.oInteractType == INTERACT_WARP_DOOR then
            return false
        end

        local apparition = obj_get_first_with_behavior_id(id_bhvApparition)
        if apparition ~= nil and o.oInteractType == INTERACT_DOOR then
            return false
        end
    elseif gNetworkPlayers[m.playerIndex].currLevelNum == LEVEL_BOB then
        if o.oInteractType == INTERACT_STAR_OR_KEY then
            m.healCounter = 31
            m.hurtCounter = 0
            spawn_mist_particles()
            play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)

            local starId = (o.oBehParams >> 24) + 1
            if network_is_server() then
                on_packet_receive({ id = PACKET_STAR, starId = starId })
            else
                network_send(true, { id = PACKET_STAR, starId = starId })
            end

            obj_mark_for_deletion(o)

            return false
        end
    end

    return true
end

function on_packet_receive(dataTable)
    if dataTable.id == PACKET_STAR then
        if network_is_server() then
            mod_storage_save(dataTable.starId .. "_collected", "true")
            gGlobalSyncTable.stars = mod_storage_get_total_star_count()
        end

        obj_mark_for_deletion(obj_get_star_by_id(dataTable.starId))
    end
end

gLevelValues.floorLowerLimit = -20000
gLevelValues.floorLowerLimitMisc = -20000 + 1000
gLevelValues.floorLowerLimitShadow = -20000 + 1000.0
gLevelValues.fixCollisionBugs = 1

if _G.DayNightCycle ~= nil then _G.DayNightCycle.enabled = false end

smlua_text_utils_course_acts_replace(COURSE_BOB, "   The Underworld", "The Land of the Condemned", "The Land of the Condemned", "The Land of the Condemned", "The Land of the Condemned", "The Land of the Condemned", "The Land of the Condemned")

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_SYNC_VALID, on_sync_valid)
hook_event(HOOK_ON_PLAYER_DISCONNECTED, on_player_disconnected)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)
hook_event(HOOK_USE_ACT_SELECT, function() return false end)

hook_mario_action(ACT_CUTSCENE, act_cutscene)
hook_mario_action(ACT_CUTSCENE_BETRAYAL, act_cutscene_betrayal)
hook_mario_action(ACT_FALLING_SPAWN, act_falling_spawn)
hook_mario_action(ACT_GETTING_SUCKED_IN, act_getting_sucked_in)