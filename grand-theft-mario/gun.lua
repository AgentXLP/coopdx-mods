define_custom_obj_fields({
    oGunTimer = 'u32',
    oGunOwner = 'u32',
})

function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    return is_player_active(m)
end

function bhv_gun_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.12)

    obj.hitboxRadius = 0
    obj.hitboxHeight = 0

    obj.oGunTimer = 300 -- 10 second wait until automatic gun deletion occurs

    network_init_object(obj, true, { 'oGunOwner' })
end

function bhv_gun_loop(obj)
    local np = network_player_from_global_index(obj.oGunOwner)
    if np == nil then
        obj_mark_for_deletion(obj)
        return
    end

    local m = gMarioStates[np.localIndex]
    if not active_player(m) then
        obj_mark_for_deletion(obj)
        return
    end
 
    if m.action ~= ACT_FLYING and (m.action & ACT_FLAG_SWIMMING) == 0 then
        obj.oPosX = get_hand_foot_pos_x(m, 0)
        obj.oPosY = get_hand_foot_pos_y(m, 0)
        obj.oPosZ = get_hand_foot_pos_z(m, 0)
    else
        obj.oPosX = m.pos.x
        obj.oPosY = m.pos.y
        obj.oPosZ = m.pos.z
    end
    obj.oFaceAnglePitch = 0
    obj.oFaceAngleYaw = m.faceAngle.y
    obj.oFaceAngleRoll = 0

    if obj.oPosX == obj.header.gfx.prevPos.x and obj.oPosY == obj.header.gfx.prevPos.y and (m.action & ACT_FLAG_SWIMMING) == 0 and obj.oPosZ == obj.header.gfx.prevPos.z then
        obj.oGunTimer = obj.oGunTimer - 1
    else
        obj.oGunTimer = 60
    end

    if obj.oGunTimer == 0 then
        obj_mark_for_deletion(obj)
    end
end

id_bhvGun = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_gun_init, bhv_gun_loop)