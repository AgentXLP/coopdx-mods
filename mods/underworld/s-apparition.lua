musicChanged = false
dialog = true

-- localize functions to improve performance
local network_local_index_from_global,vec3f_copy,vec3f_set,dist_between_objects,lateral_dist_between_objects,play_sound,spawn_mist_particles,smlua_anim_util_set_animation,mario_set_forward_vel,set_mario_action,disable_time_stop_including_mario,sqrf,approach_s16_symmetric,cur_obj_move_standard,cur_obj_update_floor_height,spawn_non_sync_object,minf,find_floor_height,vec3f_to_object_pos,obj_get_first_with_behavior_id,obj_mark_for_deletion,play_music,nearest_mario_state_to_object,obj_turn_toward_object,obj_get_next_with_same_behavior_id,stop_background_music,obj_angle_to_object,set_override_envfx,network_is_server,mod_storage_save,djui_hud_set_resolution,djui_hud_set_font,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,clamp,djui_hud_render_rect,hud_render_power_meter,spawn_sync_object = network_local_index_from_global,vec3f_copy,vec3f_set,dist_between_objects,lateral_dist_between_objects,play_sound,spawn_mist_particles,smlua_anim_util_set_animation,mario_set_forward_vel,set_mario_action,disable_time_stop_including_mario,sqrf,approach_s16_symmetric,cur_obj_move_standard,cur_obj_update_floor_height,spawn_non_sync_object,minf,find_floor_height,vec3f_to_object_pos,obj_get_first_with_behavior_id,obj_mark_for_deletion,play_music,nearest_mario_state_to_object,obj_turn_toward_object,obj_get_next_with_same_behavior_id,stop_background_music,obj_angle_to_object,set_override_envfx,network_is_server,mod_storage_save,djui_hud_set_resolution,djui_hud_set_font,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_set_color,clamp,djui_hud_render_rect,hud_render_power_meter,spawn_sync_object

local function rng()
    return math.random(0, 10) == 10
end

--- @param o Object
local function bhv_apparition_init(o)
    o.oFaceAngleYaw = 0
    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0

    o.oGravity = 0
    o.oBounciness = 0
    o.oDragStrength = 0
    o.oFriction = 0.7
    o.oBuoyancy = 0

    o.oWallHitboxRadius = 37
    o.hitboxRadius = 37
    o.hitboxHeight = 160
    o.hurtboxRadius = o.hitboxRadius
    o.hurtboxHeight = o.hurtboxHeight

    o.oIntangibleTimer = 0

    local m = gMarioStates[network_local_index_from_global(o.oOwner)]
    if m ~= nil then
        m.pos.y = m.floorHeight
        m.marioObj.header.gfx.pos.y = m.pos.y
        local angle = atan2s(-1700 - m.pos.z, 0 - m.pos.x)
        m.faceAngle.y = angle
        m.marioObj.header.gfx.angle.y = angle
        m.pos.x = m.pos.x + sins(m.faceAngle.y) * 400
        m.pos.z = m.pos.z + coss(m.faceAngle.y) * 400

        vec3f_copy(gMarioStates[0].pos, m.pos)
    end

    o.oOwner = -1
    o.oNpcTalkingTo = -1
    o.oDialogId = 5

    vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY, o.oPosZ)

    network_init_object(o, true, { "oOwner", "oHealth", "oNpcTalkingTo", "oDialogId" })
end

--- @param o Object
--- @param m MarioState
local function apparition_handle_attacks(o, m, action)
    if m.playerIndex ~= 0 or o.oInteractStatus == 0 then return end

    -- push away players bouncing on its head
    if (o.oInteractStatus & INT_STATUS_INTERACTED) ~= 0 and m.pos.y > o.oPosY + 120 and (m.action == ACT_JUMP or m.action == ACT_FORWARD_AIR_KB or m.action == ACT_BACKWARD_AIR_KB) and lateral_dist_between_objects(m.marioObj, o) < 70 then
        m.forwardVel = 70
        play_sound(SOUND_OBJ_FLAME_BLOWN, m.marioObj.header.gfx.cameraToObject)
    end

    if (m.action & ACT_FLAG_ATTACKING) ~= 0 then
        if m.action == ACT_GROUND_POUND then
            o.oHealth = o.oHealth - 40
        else
            o.oHealth = o.oHealth - 10
        end
        m.forwardVel = -48
        o.oInteractStatus = 0
        if action == 2 then
            o.oVelY = 100
        end
        o.oAction = action
        spawn_mist_particles()
        network_send_object(o, true)
    end
end

--- @param o Object
--- @param m MarioState
local function apparition_update_cutscene(o, m)
    if o.oTimer >= 240 or o.oAction ~= 0 then
        if is_playing_custom_cutscene_apparition_battle() then
            end_custom_cutscene()
        end
        return true
    end

    if not gCustomCutscene.playing then
        start_custom_cutscene_apparition_battle(o, true)
    end

    m.health = 0x880
    if o.oTimer == 1 then
        m.pos.y = m.floorHeight
        m.marioObj.header.gfx.pos.y = m.pos.y
        local angle = atan2s(o.oPosZ - m.pos.z, o.oPosX - m.pos.x)
        m.faceAngle.y = angle
        m.marioObj.header.gfx.angle.y = angle

        spawn_mist_particles()
        play_sound(SOUND_GENERAL_VANISH_SFX, m.marioObj.header.gfx.cameraToObject)
    end

    return false
end

--- @param o Object
--- @param m MarioState
local function apparition_battle(o, m)
    local played = if_then_else(o.oAction == 0, apparition_update_cutscene(o, m), true)

    switch(o.oAction, {
        [0] = function()
            smlua_anim_util_set_animation(o, "apparition_idle")
            if dist_between_objects(m.marioObj, o) < 3000 then
                m.freeze = 1
                mario_set_forward_vel(m, 0)
                -- init the battle
                if m.action ~= ACT_CUTSCENE and played then
                    if dialog then
                        o.oNpcTalkingTo = gNetworkPlayers[m.playerIndex].globalIndex
                        o.oDialogId = 4
                        start_dialog(o.oDialogId, o, true, true, 500)
                        set_mario_action(m, ACT_CUTSCENE, 0)
                        dialog = false
                    end

                    o.oAction = 1
                end
            end
            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 65, o.oPosZ)
            vec3f_set(o.header.gfx.angle, 0, o.oFaceAngleYaw, 0)
        end,
        [1] = function()
            if m.action ~= ACT_CUTSCENE then
                o.oAction = 2
            else
                disable_time_stop_including_mario()
            end
        end,
        [2] = function()
            o.oOwner = -1
            o.oGravity = 0
            o.header.gfx.angle.y = o.oTimer * 0x2000
            smlua_anim_util_set_animation(o, "apparition_twirling")

            -- twirling sound
            if o.oTimer % 9 == 0 then
                play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
            end

            -- use some math to twirl towards the player
            if o.oTimer > 60 or o.oAnimState == 1 then
                o.oAnimState = 1
                local angle = atan2s(math.sqrt(sqrf(m.pos.x - o.oPosX) + sqrf(m.pos.z - o.oPosZ)), m.pos.y + 100 - o.oPosY)
                o.oMoveAnglePitch = approach_s16_symmetric(o.oMoveAnglePitch, angle, 0x1000)
                o.oVelY = sins(o.oMoveAnglePitch) * 30
                o.oForwardVel = coss(o.oMoveAnglePitch) * 30
                cur_obj_move_standard(-78)
                cur_obj_update_floor_height()

                -- play a sound if a wall is hit or start running if contact with the ground is made
                if (o.oMoveFlags & OBJ_MOVE_HIT_WALL) ~= 0 then
                    play_sound(SOUND_ACTION_HIT, m.marioObj.header.gfx.cameraToObject)
                elseif (o.oMoveFlags & OBJ_MOVE_ON_GROUND) ~= 0 or o.oPosY <= o.oFloorHeight then
                    o.oAction = 3
                end

                if o.oTimer ~= 0 and o.oTimer % 90 == 0 and rng() then
                    o.oAction = 5
                end

                -- when attacked, start running at the player
                apparition_handle_attacks(o, m, 3)
            end

            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 65, o.oPosZ)
        end,
        [3] = function()
            o.oGravity = -5
            o.oForwardVel = 31
            smlua_anim_util_set_animation(o, "apparition_running")
            o.header.gfx.animInfo.animAccel = 65536 * 5

            -- spawn mist to better sell the effect of moving fast
            spawn_non_sync_object(
                id_bhvMistParticleSpawner,
                E_MODEL_MIST,
                o.oPosX, o.oPosY, o.oPosZ,
                nil
            )

            cur_obj_move_standard(-78)
            -- try to always be on top of the floor
            o.oPosY = minf(find_floor_height(o.oPosX + sins(o.oFaceAngleYaw) * o.oForwardVel, o.oPosY + 1000, o.oPosZ + coss(o.oFaceAngleYaw) * o.oForwardVel), m.pos.y)

            if o.oTimer % 30 == 0 then
                if dist_between_objects(o, m.marioObj) > 1000 then
                    o.oAction = 2
                end
            end

            -- anti stuck
            if o.oPosX == o.header.gfx.prevPos.x and o.oPosZ == o.header.gfx.prevPos.z then
                o.oPosX = o.oPosX + sins(o.oFaceAngleYaw) * 60
                o.oPosZ = o.oPosZ + coss(o.oFaceAngleYaw) * 60
            end

            -- when attacked, the action will change
            apparition_handle_attacks(o, m, math.random(3, 6))

            -- footsteps
            if o.oTimer % 5 == 0 then
                play_sound(SOUND_ACTION_TERRAIN_STEP, m.marioObj.header.gfx.cameraToObject)
            end

            if o.oTimer % 30 == 0 and rng() then
                o.oAction = 6
            end

            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 65, o.oPosZ)
        end,
        [4] = function()
            o.oGravity = 0
            smlua_anim_util_set_animation(o, "apparition_twirling")
            o.header.gfx.animInfo.animAccel = 65536
            o.header.gfx.angle.y = o.oTimer * 0x2000
            o.oFaceAngleYaw = o.header.gfx.angle.y

            -- twirling sound
            if o.oTimer % 12 == 0 then
                play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
            end

            -- twirl back to starting position
            if o.oTimer <= 30 then
                vec3f_to_object_pos(o, vec3f_lerp({ x = o.oPosX, y = o.oPosY, z = o.oPosZ }, { x = 0, y = 500, z = -1700 }, o.oTimer / 30))
            else
                if o.oTimer >= 60 and obj_get_first_with_behavior_id(id_bhvFlameFloatingLanding) == nil then
                    for i = 1, 8 do
                        for _ = 0, 7 do
                            spawn_non_sync_object(
                                id_bhvFlameFloatingLanding,
                                E_MODEL_RED_FLAME,
                                o.oPosX, o.oPosY, o.oPosZ,
                                --- @param obj Object
                                function(obj)
                                    obj.oForwardVel = 70
                                    obj.oFaceAngleYaw = 0x2000 * i
                                end
                            )
                        end
                    end
                    o.oAction = 2
                end
            end

            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 65, o.oPosZ)
        end,
        [5] = function()
            smlua_anim_util_set_animation(o, "apparition_twirling")
            o.header.gfx.animInfo.animAccel = 65536

            -- twirling sound
            if o.oTimer % 6 == 0 then
                play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject)
            end

            -- bounce
            cur_obj_move_standard(-78)
            if o.oPosY <= o.oFloorHeight then
                play_sound(SOUND_ACTION_TERRAIN_HEAVY_LANDING, m.marioObj.header.gfx.cameraToObject)
                spawn_mist_particles()
                o.oVelY = 40
            end

            -- add y velocity to y pos and negate
            o.oPosY = o.oPosY + o.oVelY
            o.oVelY = o.oVelY - 3

            apparition_handle_attacks(o, m, 3)

            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 65, o.oPosZ)
            o.header.gfx.angle.y = o.oTimer * 0x3000
        end,
        [6] = function()
            smlua_anim_util_set_animation(o, "apparition_raise_arm")
            o.header.gfx.animInfo.animAccel = 65536

            if o.oTimer == 10 then
                spawn_non_sync_object(
                    id_bhvOrb,
                    E_MODEL_ORB,
                    o.oPosX, o.oPosY + 300, o.oPosZ,
                    nil
                )
            elseif o.oTimer == 64 then
                play_sound(SOUND_GENERAL_VANISH_SFX, m.marioObj.header.gfx.cameraToObject)
                for i = 1, 2 do
                    spawn_non_sync_object(
                        id_bhvNoiseAttack,
                        E_MODEL_NOISE,
                        o.oPosX, o.oPosY + 300 + 200 * i, o.oPosZ,
                        nil
                    )
                end
                o.oAction = 3
            end

            if (o.oInteractStatus & INT_STATUS_INTERACTED) ~= 0 and (m.action & ACT_FLAG_ATTACKING) ~= 0 then
                m.forwardVel = 48
                o.oHealth = o.oHealth - 50
                o.oInteractStatus = 0
            end
        end
    })

    local orb = obj_get_first_with_behavior_id(id_bhvOrb)
    if o.oAction ~= 6 and orb ~= nil then
        obj_mark_for_deletion(orb)
    end

    if not musicChanged then
        musicChanged = true
        play_music(0, SEQUENCE_ARGS(8, SEQ_LEVEL_BOSS_KOOPA_FINAL), 0)
    end
end

--- @param o Object
local function bhv_apparition_loop(o)
    apparition = true

    o.globalPlayerIndex = gNetworkPlayers[0].globalIndex

    --- @type MarioState
    local m = if_then_else(o.oOwner >= 0, gMarioStates[network_local_index_from_global(o.oOwner)], nearest_mario_state_to_object(o))
    if m == nil then
        obj_mark_for_deletion(o)
        return
    end

    cur_obj_update_floor()
    if (o.oFloor ~= nil and o.oFloor.type == SURFACE_DEATH_PLANE) or m.health <= 0xff then
        o.oPosX = 0
        o.oPosY = 500
        o.oPosZ = -1700
    end

    if lateral_dist_between_objects(o, m.marioObj) > 100 then
        o.oFaceAngleYaw = obj_turn_toward_object(o, m.marioObj, 16, 0x1000)
    else
        o.oFaceAngleYaw = atan2s(m.pos.z - o.oPosZ, m.pos.x - o.oPosX)
    end

    if o.oHealth > 0 and o.oHealth <= 2048 then
        o.oInteractType = INTERACT_BOUNCE_TOP
        o.oDamageOrCoinValue = 1

        if o.oAction > 1 then
            m = nearest_mario_state_to_object(o)
        end

        -- basically wait until m isn't nil
        if m ~= nil then
            apparition_battle(o, m)
        end

        if o.oAction ~= 2 then
            vec3f_set(o.header.gfx.angle, 0, o.oFaceAngleYaw, 0)
        end
    else
        gMarioStates[0].freeze = 1
        gMarioStates[0].pos.y = gMarioStates[0].floorHeight

        local flame = obj_get_first_with_behavior_id(id_bhvFlame)
        while flame ~= nil do
            obj_mark_for_deletion(flame)
            flame = obj_get_next_with_same_behavior_id(flame)
        end

        if o.oAction < 99 then
            play_sound(SOUND_OBJ_KING_WHOMP_DEATH, m.marioObj.header.gfx.cameraToObject)
            spawn_mist_particles()
            smlua_anim_util_set_animation(o, "apparition_death")
            o.header.gfx.animInfo.animAccel = 65536
            stop_background_music(SEQ_LEVEL_BOSS_KOOPA_FINAL)
            o.oAction = 99
            network_send_object(o, true)
        elseif o.oAction == 99 then
            smlua_anim_util_set_animation(o, "apparition_death")
            o.header.gfx.animInfo.animAccel = 65536
            o.oNpcTalkingTo = gNetworkPlayers[m.playerIndex].globalIndex
            o.oDialogId = 5
            start_dialog(o.oDialogId, o, true, true, 300)
            set_mario_action(gMarioStates[0], ACT_CUTSCENE, 0)
            gMarioStates[0].marioObj.header.gfx.angle.y = obj_angle_to_object(gMarioStates[0].marioObj, o)
            gMarioStates[0].marioObj.header.gfx.pos.y = gMarioStates[0].pos.y

            o.oPosY = find_floor_height(o.oPosX, o.oPosY + 200, o.oPosZ)
            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 15, o.oPosZ)
        elseif o.oAction == 100 then
            smlua_anim_util_set_animation(o, "apparition_dead")
            o.header.gfx.animInfo.animAccel = 65536
            o.oPosY = o.oPosY + 10
            vec3f_set(o.header.gfx.pos, o.oPosX, o.oPosY + 15, o.oPosZ)
            o.header.gfx.angle.x = o.header.gfx.angle.x + 0x1500
            o.header.gfx.angle.y = o.header.gfx.angle.y + 0x1500
            o.header.gfx.angle.z = o.header.gfx.angle.z + 0x1500

            if o.oTimer == 120 then
                flashAlpha = 255
                gMarioStates[0].floor.type = SURFACE_INSTANT_WARP_1B
                set_override_envfx(ENVFX_MODE_NONE)
                if network_is_server() then
                    for i = 1, STARS do
                        mod_storage_save(i .. "_collected", "false")
                    end
                    gGlobalSyncTable.stars = 0
                end
            end
        end
    end
end

id_bhvApparition = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_apparition_init, bhv_apparition_loop)

local hudHealth = 0
local function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_TINY)

    local scale = 1

    local hWidth = djui_hud_get_screen_width() * 0.5

    local apparition = obj_get_first_with_behavior_id(id_bhvApparition)
    if apparition ~= nil and apparition.oAction == 0 then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        local width = djui_hud_get_screen_width()
        local height = djui_hud_get_screen_height()

        djui_hud_set_color(0, 0, 0, clamp((1 - apparition.oTimer / 60) * 255, 0, 255))
        djui_hud_render_rect(0, 0, width, height)
    end

    djui_hud_set_resolution(RESOLUTION_N64)

    if apparition == nil or apparition.oAction == 0 then return end

    djui_hud_set_color(0, 0, 0, 127)
    djui_hud_print_text_centered("THE SHITILIZER", hWidth, 11, scale)
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_centered("THE SHITILIZER", hWidth, 10, scale)

    djui_hud_set_color(0, 127, 127, 255)
    djui_hud_render_rect(hWidth - 75, 30, 150, 10)
    djui_hud_set_color(0, 255, 255, 255)
    hudHealth = approach_number(hudHealth, apparition.oHealth, 2048, 10)
    djui_hud_render_rect(hWidth - 75, 30, hudHealth / 2048 * 150, 10)

    djui_hud_set_color(255, 255, 255, 255)
    hud_render_power_meter(gMarioStates[0].health, djui_hud_get_screen_width() - 64, 0, 64, 64)
end

--- @param m MarioState
local function on_set_mario_action(m)
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_COURTYARD and (m.prevAction == ACT_PUSHING_DOOR or m.prevAction == ACT_PULLING_DOOR) and obj_get_first_with_behavior_id(id_bhvApparition) == nil then
        if m.playerIndex == 0 then
            spawn_sync_object(
                id_bhvApparition,
                E_MODEL_APPARITION,
                0, 500, -1700,
                --- @param o Object
                function(o)
                    o.oOwner = gNetworkPlayers[0].globalIndex
                end
            )
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)