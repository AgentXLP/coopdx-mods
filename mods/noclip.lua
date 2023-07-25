-- name: Noclip
-- description: Noclip\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod improves ACT_DEBUG_FREE_MOVE and makes accessible by everyone if cheats are on, otherwise only the host and moderators.

local cur_obj_scale,obj_mark_for_deletion,vec3f_to_object_pos,maxf,load_object_collision_model,obj_get_first_with_behavior_id,spawn_non_sync_object,set_mario_anim_with_accel,set_mario_animation,vec3f_add,vec3f_copy,vec3f_length,vec3s_set,set_mario_action = cur_obj_scale,obj_mark_for_deletion,vec3f_to_object_pos,maxf,load_object_collision_model,obj_get_first_with_behavior_id,spawn_non_sync_object,set_mario_anim_with_accel,set_mario_animation,vec3f_add,vec3f_copy,vec3f_length,vec3s_set,set_mario_action

local ACT_NOCLIP = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR)

local function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

--- @param o Object
local function bhv_noclip_floor_init(o)
    cur_obj_scale(2)
    o.collisionData = gGlobalObjectCollisionData.metal_box_seg8_collision_08024C28
    o.oCollisionDistance = 99999
end

--- @param o Object
local function bhv_noclip_floor_loop(o)
    if gMarioStates[0].action ~= ACT_NOCLIP then
        obj_mark_for_deletion(o)
        return
    end

    vec3f_to_object_pos(o, gMarioStates[0].pos)
    o.oPosY = maxf(o.oPosY - 10000, -11000)

    load_object_collision_model()
end

local id_bhvNoclipFloor = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_noclip_floor_init, bhv_noclip_floor_loop)

--- @param m MarioState
local function act_noclip(m)
    local vel = { x = 0, y = 0, z = 0 }

    local speed = if_then_else((m.controller.buttonDown & B_BUTTON) ~= 0, 1, 4)

    if (m.controller.buttonDown & A_BUTTON) ~= 0 then
        vel.y = vel.y + 16 * speed
    end
    if (m.controller.buttonDown & Z_TRIG) ~= 0 then
        vel.y = vel.y - 16 * speed
    end

    local noclipFloor = obj_get_first_with_behavior_id(id_bhvNoclipFloor)
    if noclipFloor == nil then
        spawn_non_sync_object(
            id_bhvNoclipFloor,
            E_MODEL_NONE,
            m.pos.x, m.pos.y - 1000, m.pos.z,
            nil
        )
    end

    if m.intendedMag > 0 then
        vel.x = vel.x + 26 * speed * sins(m.intendedYaw)
        vel.z = vel.z + 26 * speed * coss(m.intendedYaw)

        set_mario_anim_with_accel(m, MARIO_ANIM_WALKING, 65536 * speed * 1.5)
    else
        set_mario_animation(m, MARIO_ANIM_DOUBLE_JUMP_FALL)
    end

    vec3f_add(m.pos, vel)
    vec3f_copy(m.vel, vel)
    m.forwardVel = vec3f_length({ x = vel.x, y = 0, z = m.vel.z })

    m.faceAngle.y = m.intendedYaw
    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    vec3s_set(m.marioObj.header.gfx.angle, 0, m.faceAngle.y, 0)

    if (m.controller.buttonPressed & L_TRIG) ~= 0 and m.marioObj.oTimer > 10 then
        set_mario_action(m, if_then_else(m.pos.y <= m.waterLevel - 100, ACT_WATER_IDLE, ACT_IDLE), 0)
    end

    if (m.controller.buttonDown & X_BUTTON) ~= 0 then
        cur_obj_hide()
    else
        cur_obj_unhide()
    end
end

--- @param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_DEBUG_FREE_MOVE or ((m.controller.buttonDown & L_TRIG) ~= 0 and (m.controller.buttonDown & Z_TRIG) ~= 0 and (gServerSettings.enableCheats or network_is_server() or network_is_moderator())) then
        set_mario_action(m, ACT_NOCLIP, 0)
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

hook_mario_action(ACT_NOCLIP, act_noclip)