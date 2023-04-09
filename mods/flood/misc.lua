if unsupported then return end

E_MODEL_FLOOD = smlua_model_util_get_id("flood_geo")
local E_MODEL_BLOOD = smlua_model_util_get_id("blood_geo")
E_MODEL_CTT = smlua_model_util_get_id("ctt_geo") -- easter egg in the distance
E_MODEL_LAUNCHPAD = smlua_model_util_get_id("launchpad_geo")

local COL_LAUNCHPAD = smlua_collision_util_get("launchpad_collision")

-- localize functions to improve performance
local bhv_pole_base_loop = bhv_pole_base_loop
local set_camera_shake_from_hit = set_camera_shake_from_hit
local djui_chat_message_create = djui_chat_message_create
local play_music = play_music
local play_sound = play_sound
local mario_set_forward_vel = mario_set_forward_vel
local play_mario_jump_sound = play_mario_jump_sound
local set_mario_action = set_mario_action
local vec3f_set = vec3f_set
local network_discord_id_from_local_index = network_discord_id_from_local_index
local network_is_server = network_is_server
local nearest_mario_state_to_object = nearest_mario_state_to_object
local spawn_orange_number = spawn_orange_number
local cur_obj_init_animation = cur_obj_init_animation
local cur_obj_scale = cur_obj_scale
local lateral_dist_between_objects = lateral_dist_between_objects
local obj_mark_for_deletion = obj_mark_for_deletion
local obj_scale = obj_scale
local smlua_collision_util_get = smlua_collision_util_get
local get_environment_region = get_environment_region
local set_environment_region = set_environment_region
local set_override_far = set_override_far
local smlua_model_util_get_id = smlua_model_util_get_id
local obj_check_hitbox_overlap = obj_check_hitbox_overlap
local obj_get_first_with_behavior_id = obj_get_first_with_behavior_id
local obj_get_nearest_object_with_behavior_id = obj_get_nearest_object_with_behavior_id
local obj_has_behavior_id = obj_has_behavior_id
local obj_set_model_extended = obj_set_model_extended
local spawn_non_sync_object = spawn_non_sync_object
local smlua_text_utils_course_acts_replace = smlua_text_utils_course_acts_replace
local load_object_collision_model = load_object_collision_model

--- @param o Object
local function bhv_water_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oAnimState = gLevels[gGlobalSyncTable.level].type

    o.header.gfx.skipInViewCheck = true

    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0
end

--- @param o Object
local function bhv_water_loop(o)
    o.oPosY = gGlobalSyncTable.waterLevel

    if gGlobalSyncTable.level ~= LEVEL_SSL then
        o.oFaceAngleYaw = o.oTimer * 14
    end

    if gNetworkPlayers[0].currLevelNum ~= LEVEL_WDW then
        for i = 1, 3 do
            if get_environment_region(i) < gGlobalSyncTable.waterLevel then
                set_environment_region(i, -20000)
            end
        end
    else
        set_environment_region(1, -20000)
    end

    -- priority: needle, agent, blocky
    if needlemouse_in_server() and gNetworkPlayers[0].currLevelNum == LEVEL_TTC and o.oAnimState ~= 1 and o.oAction == 0 then
        o.oAnimState = 1
        smlua_text_utils_course_acts_replace(COURSE_TTC, "    Tit Tock Cock", "CUMMIES", "CUMMIES", "CUMMIES", "CUMMIES", "CUMMIES", "CUMMIES")
        djui_chat_message_create("Cummies Mode Activated")
        play_sound(SOUND_MENU_MESSAGE_DISAPPEAR, gMarioStates[0].marioObj.header.gfx.cameraToObject)
    end

    if o.oAction == 2 then
        o.oAnimState = 4
        obj_set_model_extended(o, E_MODEL_FLOOD)
    elseif o.oAction == 1 then
        obj_set_model_extended(o, E_MODEL_BLOOD)
        set_camera_shake_from_hit(SHAKE_SHOCK)
    end
end

id_bhvWater = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_water_init, bhv_water_loop)


--- @param o Object
local function bhv_custom_static_object_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.skipInViewCheck = true
    set_override_far(50000)
end

id_bhvCustomStaticObject = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_custom_static_object_init, nil)


--- @param o Object
local function bhv_final_star_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.hitboxRadius = 160
    o.hitboxHeight = 100

    cur_obj_scale(2)
end

--- @param o Object
local function bhv_final_star_loop(o)
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x800
end

id_bhvFinalStar = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_final_star_init, bhv_final_star_loop)


local function bhv_launchpad_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oCollisionDistance = 500
    o.collisionData = COL_LAUNCHPAD
    obj_scale(o, 0.85)
end

local function bhv_launchpad_loop(o)
    local m = nearest_mario_state_to_object(o)
    if m.marioObj.platform == o then
        play_mario_jump_sound(m)
        if o.oBehParams2ndByte ~= 0x69 then -- humor
            set_mario_action(m, ACT_TWIRLING, 0)
            m.vel.y = o.oBehParams2ndByte
        else
            spawn_non_sync_object(
                id_bhvWingCap,
                E_MODEL_MARIOS_WING_CAP,
                m.pos.x + m.vel.x, m.pos.y + m.vel.y, m.pos.z + m.vel.z,
                nil
            )
            vec3f_set(m.angleVel, 0, 0, 0)
            set_mario_action(m, ACT_FLYING_TRIPLE_JUMP, 0)
            m.vel.y = 55
            mario_set_forward_vel(m, 100)
            vec3f_set(m.angleVel, 0, 0, 0)
            m.faceAngle.y = 0x4500
        end
    end
    load_object_collision_model()
end

id_bhvLaunchpad = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_launchpad_init, bhv_launchpad_loop)

--- @param o Object
local function bhv_flood_flag_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_POLE
    o.hitboxRadius = 80
    o.hitboxHeight = 700
    o.oIntangibleTimer = 0
    o.oAnimations = gObjectAnimations.koopa_flag_seg6_anims_06001028

    cur_obj_init_animation(0)
end

--- @param o Object
local function bhv_flood_flag_loop(o)
    bhv_pole_base_loop()
end

id_bhvFloodFlag = hook_behavior(nil, OBJ_LIST_POLELIKE, true, bhv_flood_flag_init, bhv_flood_flag_loop)


--- @param o Object
local function obj_hide(o)
    o.header.gfx.node.flags = o.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
end

--- @param o Object
local function obj_mark_for_deletion_on_sync(o)
    if gNetworkPlayers[0].currAreaSyncValid then obj_mark_for_deletion(o) end
end

--- @param o Object
local function delete_easy_stars(o)
    local flag = obj_get_nearest_object_with_behavior_id(o, id_bhvFloodFlag)
    if flag ~= nil and lateral_dist_between_objects(o, flag) < 2000 then
        obj_mark_for_deletion(o)
    end
end

--- @param o Object
local function delete_if_not_rr(o)
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_RR and gNetworkPlayers[0].currAreaSyncValid then
        obj_mark_for_deletion(o)
    end
end

--- @param o Object
local function delete_if_wdw_or_thi(o)
    if (gNetworkPlayers[0].currLevelNum == LEVEL_WDW or gNetworkPlayers[0].currLevelNum == LEVEL_THI) and o.oBehParams2ndByte >= 8 and gNetworkPlayers[0].currAreaSyncValid then
        obj_mark_for_deletion(o)
    end
end

hook_behavior(id_bhvStar, OBJ_LIST_LEVEL, false, nil, delete_easy_stars)
hook_behavior(id_bhvHoot, OBJ_LIST_UNIMPORTANT, true, obj_hide, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvWarpPipe, OBJ_LIST_UNIMPORTANT, true, obj_hide, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvFadingWarp, OBJ_LIST_UNIMPORTANT, true, obj_hide, delete_if_not_rr)
hook_behavior(id_bhvBalconyBigBoo, OBJ_LIST_UNIMPORTANT, true, obj_hide, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvExclamationBox, OBJ_LIST_SURFACE, false, nil, delete_if_wdw_or_thi)
hook_behavior(id_bhvWaterLevelDiamond, OBJ_LIST_UNIMPORTANT, true, obj_hide, obj_mark_for_deletion_on_sync)

--- @param m MarioState
local function before_phys_step(m)
    if m.playerIndex ~= 0 then return end

    if m.pos.y + 40 < gGlobalSyncTable.waterLevel and gNetworkPlayers[m.playerIndex].currLevelNum == gGlobalSyncTable.level then
        m.vel.y = m.vel.y + 2
        m.peakHeight = m.pos.y
    end
end

--- @param m MarioState
--- @param o Object
local function allow_interact(m, o)
    if m.action == ACT_SPECTATOR or m.action == ACT_PAUSE or (o.header.gfx.node.flags & GRAPH_RENDER_ACTIVE) == 0 then return false end
    if o.oInteractType == INTERACT_WARP_DOOR or
    o.oInteractType == INTERACT_WARP then return false end
    if o.oInteractType == INTERACT_STAR_OR_KEY then
        m.healCounter = 31
        m.hurtCounter = 0
        if m.playerIndex == 0 then
            savedStarPoints = savedStarPoints + gLevels[gGlobalSyncTable.level].starPoints
        end
        if gServerSettings.enableCheats == 0 then
            spawn_orange_number(math_round(savedStarPoints * savedSpeedMultiplier), 0, 0, 0)
        end
    end

    return true
end

local function on_death()
    local m = gMarioStates[0]
    if m.floor.type == SURFACE_DEATH_PLANE or m.floor.type == SURFACE_VERTICAL_WIND then
        m.health = 0xff
    end
    return false
end

local function on_pause_exit()
    if network_is_server() then
        network_send(true, { restart = true })
        level_restart()
    end
    return false
end

--- @param m MarioState
local function allow_hazard_surface(m)
    if m.health <= 0xff then return false end
    return true
end

--- @param messageSender MarioState
local function on_chat_message(messageSender, message)
    if screen then return false end

    if network_discord_id_from_local_index(messageSender.playerIndex) == "584329002689363968" and message:find("murder is based") then
        local water = obj_get_first_with_behavior_id(id_bhvWater)
        if water ~= nil then
            water.oAction = 1
            play_music(0, SEQUENCE_ARGS(4, SEQ_EVENT_ENDLESS_STAIRS), 255)
        end
    elseif network_discord_id_from_local_index(messageSender.playerIndex) == "490613035237507091" and message:find("strawberry milk is based") then
        local water = obj_get_first_with_behavior_id(id_bhvWater)
        if water ~= nil then
            water.oAction = 2
            play_music(0, SEQUENCE_ARGS(8, SEQ_LEVEL_WATER), 255)
        end
    end
    return true
end

-- thanks Peachy
--- @param o Object
local function on_object_unload(o)
    local m = gMarioStates[0]
    if (o.header.gfx.node.flags & GRAPH_RENDER_INVISIBLE) == 0 and obj_has_behavior_id(o, id_bhv1Up) == 1 and obj_check_hitbox_overlap(o, m.marioObj) then
        m.healCounter = 31
        m.hurtCounter = 0
    end
end

hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_event(HOOK_ON_DEATH, on_death)
hook_event(HOOK_ON_PAUSE_EXIT, on_pause_exit)
hook_event(HOOK_ALLOW_HAZARD_SURFACE, allow_hazard_surface)
hook_event(HOOK_ON_CHAT_MESSAGE, on_chat_message)
hook_event(HOOK_ON_OBJECT_UNLOAD, on_object_unload)