-- localize functions to improve performance - objects.lua
local obj_scale,set_override_far,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id,nearest_player_to_object,get_network_player_smallest_global,spawn_non_sync_object,obj_set_model_extended,audio_stream_play,audio_stream_set_looping,play_sound,set_override_envfx,obj_set_billboard,cur_obj_hide,obj_mark_for_deletion,dist_between_objects,cur_obj_unhide,maxf,cur_obj_update_floor_height,mod_storage_load,cur_obj_scale,nearest_mario_state_to_object,sqrf,obj_turn_toward_object,approach_s16_symmetric,cur_obj_move_standard,obj_check_hitbox_overlap,play_character_sound = obj_scale,set_override_far,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id,nearest_player_to_object,get_network_player_smallest_global,spawn_non_sync_object,obj_set_model_extended,audio_stream_play,audio_stream_set_looping,play_sound,set_override_envfx,obj_set_billboard,cur_obj_hide,obj_mark_for_deletion,dist_between_objects,cur_obj_unhide,maxf,cur_obj_update_floor_height,mod_storage_load,cur_obj_scale,nearest_mario_state_to_object,sqrf,obj_turn_toward_object,approach_s16_symmetric,cur_obj_move_standard,obj_check_hitbox_overlap,play_character_sound

--- @param o Object
local function bhv_sky_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.skipInViewCheck = true
    o.oOpacity = 0

    o.oHomeY = o.oPosY

    if gNetworkPlayers[0].currLevelNum == LEVEL_BOB then
        obj_scale(o, 0.5)
        o.oGraphYOffset = 30000
    end

    set_override_far(200000)
end

--- @param o Object
local function bhv_sky_loop(o)
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        if obj_get_first_with_behavior_id(id_bhvRisingCastle).oAction == 2 then
            o.oOpacity = 255
        else
            o.oOpacity = 0
        end
    else
        o.oOpacity = 255
    end

    o.oPosY = o.oHomeY + math.sin(o.oTimer * 0.1) * 1000
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x100
end

id_bhvSky = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_sky_init, bhv_sky_loop)


--- @param o Object
local function bhv_rising_castle_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.skipInViewCheck = true

    network_init_object(o, true, {})
end

--- @param behaviorId BehaviorId
local function rise_every_object_with_behavior_id(behaviorId, amount)
    local obj = obj_get_first_with_behavior_id(behaviorId)
    while obj ~= nil do
        obj.oPosY = obj.oPosY + amount
        obj = obj_get_next_with_same_behavior_id(obj)
    end
end

--- @param o Object
local function bhv_rising_castle_loop(o)
    local nearest = nearest_player_to_object(o)
    if nearest ~= nil and nearest.oPosZ < 1000 and o.oAction == 0 then
        o.oAction = 1
        o.oTimer = 0
    end

    if o.oAction == 1 then
        if get_network_player_smallest_global().globalIndex == gNetworkPlayers[0].globalIndex then
            gGlobalSyncTable.castleRisingTimer = gGlobalSyncTable.castleRisingTimer + 1
        end

        if gCustomCutscene.prevCamPos.x == 0 and gCustomCutscene.prevCamPos.y == 0 and gCustomCutscene.prevCamPos.z == 0 then
            set_prev_cam_pos_and_focus()
        end

        o.oFaceAngleYaw = math.random(-100, 100)
        o.oFaceAnglePitch = math.random(-100, 100)
        o.oFaceAngleRoll = math.random(-100, 100)

        if obj_get_first_with_behavior_id(id_bhvSky) == nil then
            spawn_non_sync_object(
                id_bhvSky,
                E_MODEL_SKY,
                0, 0, 0,
                nil
            )
        end

        if o.oTimer >= 60 then
            o.oAction = 2
        end
    elseif o.oAction == 2 then
        if get_network_player_smallest_global().globalIndex == gNetworkPlayers[0].globalIndex then
            gGlobalSyncTable.castleRisingTimer = gGlobalSyncTable.castleRisingTimer + 1
        end

        obj_set_model_extended(o, E_MODEL_CASTLE_RISING)

        if o.oTimer == 1 then
            audio_stream_play(STREAM_EARTHQUAKE, true, 1)
            audio_stream_set_looping(STREAM_EARTHQUAKE, true)
            audio_stream_play(STREAM_SRIATS_SSELDNE, true, 1)
            audio_stream_set_looping(STREAM_SRIATS_SSELDNE, true)

            delete_every_object_with_behavior_id(id_bhvTree)
            delete_every_object_with_behavior_id(id_bhvBird)
            delete_every_object_with_behavior_id(id_bhvBirdsSoundLoop)

            play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, gMarioStates[0].marioObj.header.gfx.cameraToObject)
            play_sound(SOUND_GENERAL_BOWSER_BOMB_EXPLOSION, gMarioStates[0].marioObj.header.gfx.cameraToObject)

            flashAlpha = 255
        end

        set_override_envfx(ENVFX_SNOW_BLIZZARD)
        tint_lighting_color()

        if o.oPosY < 15000 then
            o.oPosY = o.oPosY + 15

            rise_every_object_with_behavior_id(id_bhvCastleFlagWaving, 15)
            rise_every_object_with_behavior_id(id_bhvDoorWarp, 15)
        end
    end
end

id_bhvRisingCastle = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_rising_castle_init, bhv_rising_castle_loop)


--- @param o Object
local function bhv_letter_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_set_billboard(o)

    cur_obj_hide()
end

--- @param o Object
local function bhv_letter_loop(o)
    if o.parentObj == nil then
        obj_mark_for_deletion(o)
        return
    end

    if o.parentObj.oNpcTalkingTo >= 0 or dist_between_objects(o, nearest_player_to_object(o)) > NPC_INTERACT_RANGE then
        cur_obj_hide()
    else
        cur_obj_unhide()
    end
end

id_bhvLetter = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_letter_init, bhv_letter_loop)


--- @param o Object
local function bhv_orb_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oHomeY = o.oPosY
end

--- @param o Object
local function bhv_orb_loop(o)
    if o.parentObj == nil or o.parentObj.activeFlags == ACTIVE_FLAG_DEACTIVATED then
        obj_mark_for_deletion(o)
        return
    end

    o.oFaceAnglePitch = o.oFaceAnglePitch + 0x2000
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x2000
    o.oFaceAngleRoll = o.oFaceAngleRoll + 0x2000
    o.oPosY = o.oHomeY + math.sin(o.oTimer * 0.3) * 20
end

id_bhvOrb = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_orb_init, bhv_orb_loop)

--- @param o Object
local function bhv_big_star_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
end

--- @param o Object
local function bhv_big_star_loop(o)
    obj_scale(o, maxf(gGlobalSyncTable.stars / STARS, 0.1) * 2.5)

    if gGlobalSyncTable.stars >= STARS then
        obj_set_model_extended(o, E_MODEL_SOUL_STAR_NOISE)
    else
        obj_set_model_extended(o, E_MODEL_STAR)
    end

    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x40 * gGlobalSyncTable.stars
end

id_bhvBigStar = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_big_star_init, bhv_big_star_loop)


--- @param o Object
local function id_bhv_grand_star_loop(o)
    obj_set_model_extended(o, E_MODEL_NORMAL_STAR)
end

id_bhvGrandStar = hook_behavior(id_bhvGrandStar, OBJ_LIST_LEVEL, false, nil, id_bhv_grand_star_loop)


--- @param o Object
local function bhv_flame_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_scale(o, 3)
    obj_set_billboard(o)

    cur_obj_update_floor_height()
    o.oPosY = o.oFloorHeight + 30

    network_init_object(o, false, {})
end

--- @param o Object
local function bhv_flame_loop(o)
    o.oAnimState = o.oTimer % 60
end

id_bhvFlame = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_flame_init, bhv_flame_loop)

local function mod_storage_get_star_collected(starId)
    return mod_storage_load(starId .. "_collected") == "true"
end

--- @param o Object
function soul_star(o)
    local starId = (o.oBehParams >> 24) + 1

    if network_is_server() and mod_storage_get_star_collected(starId) then
        obj_mark_for_deletion(o)
        return
    end
end

--- @param o Object
local function bhv_noise_attack_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.25)
end

--- @param o Object
local function bhv_noise_attack_loop(o)
    if o.oTimer >= 90 then
        obj_mark_for_deletion(o)
        return
    end

    local m = nearest_mario_state_to_object(o)
    local angle = atan2s(math.sqrt(sqrf(m.pos.x - o.oPosX) + sqrf(m.pos.z - o.oPosZ)), m.pos.y + 100 - o.oPosY)
    o.oFaceAngleYaw = obj_turn_toward_object(o, m.marioObj, 16, 0x2000)
    o.oMoveAnglePitch = approach_s16_symmetric(o.oMoveAnglePitch, angle, 0x1000)
    o.oVelY = sins(o.oMoveAnglePitch) * 30
    o.oForwardVel = coss(o.oMoveAnglePitch) * 40

    cur_obj_move_standard(-78)

    if obj_check_hitbox_overlap(o, m.marioObj) and m.invincTimer <= 0 and (m.action & (ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)) == 0 then
        m.health = m.health - 0x100
        play_character_sound(m, CHAR_SOUND_ATTACKED)
        obj_mark_for_deletion(o)
        return
    end
end

id_bhvNoiseAttack = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_noise_attack_init, bhv_noise_attack_loop)