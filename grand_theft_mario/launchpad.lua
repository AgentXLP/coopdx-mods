-- Launchpad ported from sm64js; texture by 0x2480
E_MODEL_LAUNCHPAD = smlua_model_util_get_id("launchpad_geo")
COL_LAUNCHPAD = smlua_collision_util_get("launchpad_collision")

--- @param o Object
function bhv_launchpad_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oCollisionDistance = 500
    o.collisionData = COL_LAUNCHPAD
    obj_scale(o, 0.85)
end

--- @param o Object
function bhv_launchpad_loop(o)
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
            set_mario_action(m, ACT_FLYING_TRIPLE_JUMP, 0)
            m.forwardVel = m.forwardVel + 45
            m.vel.y = 55
            m.faceAngle.y = 0x4000
        end
    end
    load_object_collision_model()
end
id_bhvLaunchpad = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_launchpad_init, bhv_launchpad_loop)