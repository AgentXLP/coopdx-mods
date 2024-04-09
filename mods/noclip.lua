-- name: Noclip
-- description: Noclip\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod is a utility mod that improves\nACT_DEBUG_FREE_MOVE and makes it easily accessible without the development build.
-- pausable: true

local cur_obj_scale,vec3f_to_object_pos,maxf,load_object_collision_model,obj_mark_for_deletion,obj_get_first_with_behavior_id,set_first_person_enabled,set_mario_action,set_character_anim_with_accel,set_character_animation,spawn_non_sync_object,vec3f_add,vec3f_copy,vec3f_length,vec3s_set,cur_obj_hide,cur_obj_unhide,network_is_moderator,network_is_server,djui_chat_message_create = cur_obj_scale,vec3f_to_object_pos,maxf,load_object_collision_model,obj_mark_for_deletion,obj_get_first_with_behavior_id,set_first_person_enabled,set_mario_action,set_character_anim_with_accel,set_character_animation,spawn_non_sync_object,vec3f_add,vec3f_copy,vec3f_length,vec3s_set,cur_obj_hide,cur_obj_unhide,network_is_moderator,network_is_server,djui_chat_message_create

local ACT_NOCLIP = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_AIR)

local fp = false

--- @param cond boolean
--- Human readable ternary operator
local function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

--- @param value boolean
--- Returns an on or off string depending on value
function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end


--- @param o Object
local function bhv_noclip_floor_init(o)
    cur_obj_scale(2)
    o.collisionData = gGlobalObjectCollisionData.metal_box_seg8_collision_08024C28
    o.oCollisionDistance = 99999
end

--- @param o Object
local function bhv_noclip_floor_loop(o)
    vec3f_to_object_pos(o, gMarioStates[0].pos)
    o.oPosY = maxf(o.oPosY - 10000, -11000)

    load_object_collision_model()
end

local id_bhvNoclipFloor = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_noclip_floor_init, bhv_noclip_floor_loop)


--- @param m MarioState
local function act_noclip(m)
    if (m.controller.buttonPressed & L_TRIG) ~= 0 and m.marioObj.oTimer > 10 then
        obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvNoclipFloor))
        if fp then
            set_first_person_enabled(false)
        end
        return set_mario_action(m, if_then_else(m.pos.y <= m.waterLevel - 100, ACT_WATER_IDLE, ACT_IDLE), 0)
    end

    local vel = { x = 0, y = 0, z = 0 }
    local speed = if_then_else((m.controller.buttonDown & B_BUTTON) ~= 0, 1, 4)

    if m.intendedMag > 0 then
        vel.x = 26 * speed * sins(m.intendedYaw)
        vel.z = 26 * speed * coss(m.intendedYaw)
        set_character_anim_with_accel(m, CHAR_ANIM_WALKING, 65536 * speed * 1.5)
    else
        set_character_animation(m, CHAR_ANIM_DOUBLE_JUMP_FALL)
    end
    if (m.controller.buttonDown & A_BUTTON) ~= 0 then
        vel.y = 16 * speed
    end
    if (m.controller.buttonDown & Z_TRIG) ~= 0 then
        vel.y = vel.y - 16 * speed
    end

    if obj_get_first_with_behavior_id(id_bhvNoclipFloor) == nil then
        spawn_non_sync_object(
            id_bhvNoclipFloor,
            E_MODEL_NONE,
            m.pos.x, m.pos.y - 1000, m.pos.z,
            nil
        )
    end

    vec3f_add(m.pos, vel)
    vec3f_copy(m.vel, vel)
    m.forwardVel = vec3f_length({ x = vel.x, y = 0, z = m.vel.z })

    m.faceAngle.y = m.intendedYaw
    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    vec3s_set(m.marioObj.header.gfx.angle, 0, m.faceAngle.y, 0)

    if (m.controller.buttonDown & X_BUTTON) ~= 0 then
        cur_obj_hide()
    else
        cur_obj_unhide()
    end

    set_first_person_enabled(fp)

    return 0
end

--- @param m MarioState
local function mario_update(m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_DEBUG_FREE_MOVE or ((m.controller.buttonDown & L_TRIG) ~= 0 and (m.controller.buttonDown & Z_TRIG) ~= 0 and (network_is_server() or network_is_moderator())) then
        set_mario_action(m, ACT_NOCLIP, 0)
    end
end


local function on_noclip_fp_command()
    fp = not fp
    djui_chat_message_create("[Noclip] First person status: " .. on_or_off(fp))
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

hook_chat_command("noclip-fp", "Toggles Noclip first person on or off", on_noclip_fp_command)

hook_mario_action(ACT_NOCLIP, act_noclip)