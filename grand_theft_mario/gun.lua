E_MODEL_ARM = smlua_model_util_get_id("arm_geo")
E_MODEL_GORDON_ARM = smlua_model_util_get_id("arm_geo")
E_MODEL_ARM_METAL = smlua_model_util_get_id("arm_metal_geo")

SOUND_CUSTOM_DRYFIRE = audio_sample_load("dry.mp3")

gunTable = {}

define_custom_obj_fields({
    oGunOwner = 'u32',
})

--- @param m MarioState
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return false
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return false
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return false
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return false
    end
    return is_player_active(m)
end


-- GUN OBJECT --

--- @param o Object
function bhv_gun_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.12)

    o.hitboxRadius = 0
    o.hitboxHeight = 0

    network_init_object(o, true, { 'oGunOwner' })
end

--- @param o Object
function bhv_gun_loop(o)
    local np = network_player_from_global_index(o.oGunOwner)
    if np == nil then
        obj_mark_for_deletion(o)
        return
    end

    local m = gMarioStates[np.localIndex]
    if not active_player(m) then
        obj_mark_for_deletion(o)
        return
    end

    if m.action ~= ACT_FLYING and (m.action & ACT_FLAG_SWIMMING) == 0 then
        -- it works, it just works.
        if o.oGunOwner ~= gNetworkPlayers[0].globalIndex then
            o.oPosX = get_hand_foot_pos_x(m, 0) + m.vel.x
            if m.action ~= ACT_JUMP then
                o.oPosY = get_hand_foot_pos_y(m, 0)
            else
                o.oPosY = get_hand_foot_pos_y(m, 0) + 25
            end
            o.oPosZ = get_hand_foot_pos_z(m, 0) + m.vel.z
        else
            if firstPerson then
                o.oPosX = m.pos.x + m.vel.x + 5 * math.sin(m.faceAngle.y)
                o.oPosY = -11000
                o.oPosZ = m.pos.z + m.vel.z + 5 * math.cos(m.faceAngle.y)
            else
                o.oPosX = get_hand_foot_pos_x(m, 0) + m.vel.x
                if m.action ~= ACT_JUMP then
                    o.oPosY = get_hand_foot_pos_y(m, 0)
                else
                    o.oPosY = get_hand_foot_pos_y(m, 0) + 25
                end
                o.oPosZ = get_hand_foot_pos_z(m, 0) + m.vel.z
            end
        end
    else
        o.oPosX = m.pos.x
        o.oPosZ = m.pos.z
        if o.oGunOwner == gNetworkPlayers[0].globalIndex and firstPerson then
            o.oPosY = -11000
        else
            o.oPosY = m.pos.y + 50
        end
    end
    o.oFaceAnglePitch = 0
    o.oFaceAngleYaw = m.faceAngle.y
    o.oFaceAngleRoll = 0
end
id_bhvGun = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_gun_init, bhv_gun_loop)

local vgun = nil
--- @param m MarioState
function gun_change(m, new)
    if gun == nil then
        return
    end
    if gPlayerSyncTable[0].gun == new and firstPerson then
        deployHeight = deployMax
    elseif firstPerson then
        deployHeight = deployMin
    end
    gPlayerSyncTable[m.playerIndex].gun = new
    local localGun = gPlayerSyncTable[0].gun
    reloadTimer = gunTable[gPlayerSyncTable[m.playerIndex].gun].reloadTime
    shootTimer = gunTable[gPlayerSyncTable[m.playerIndex].gun].shootTime

    obj_mark_for_deletion(gun)
    spawn_gun()
    if firstPerson then
        obj_mark_for_deletion(arm)
        obj_mark_for_deletion(vgun)
        arm = spawn_non_sync_object(
            id_bhvViewModel,
            get_arm_state(localGun),
            gLakituState.focus.x + (1970 * math.sin(gLakituState.yaw / 0x8000 * math.pi)),
            -11000,
            gLakituState.focus.z + (1970 * math.cos(gLakituState.yaw / 0x8000 * math.pi)),
            --- @param o Object
            function (o)
                o.oFaceAnglePitch = 0
                o.oFaceAngleYaw = gLakituState.yaw - 0x4000
                o.oFaceAngleRoll = 0
            end
        )
        vgun = spawn_non_sync_object(
            id_bhvViewModel,
            gunTable[localGun].vmodel,
            gLakituState.focus.x + (1970 * math.sin(gLakituState.yaw / 0x8000 * math.pi)),
            -11000,
            gLakituState.focus.z + (1970 * math.cos(gLakituState.yaw / 0x8000 * math.pi)),
            --- @param o Object
            function (o)
                o.oFaceAnglePitch = 0
                o.oFaceAngleYaw = gLakituState.yaw - 0x4000
                o.oFaceAngleRoll = 0
            end
        )
    end
end

function despawn_gun()
    if gun ~= nil then
        obj_mark_for_deletion(gun)
        -- gun = nil
    end
    despawn_arm()
end

function spawn_gun()
    local m = gMarioStates[0]
    gun = spawn_sync_object(
        id_bhvGun,
        gunTable[gPlayerSyncTable[0].gun].model,
        get_hand_foot_pos_x(m, 0), get_hand_foot_pos_y(m, 0), get_hand_foot_pos_z(m, 0),
        function (o)
            o.oGunOwner = gNetworkPlayers[0].globalIndex
        end
    )
end

-- VIEWMODEL --

deployHeight = -10
deployMax = 105
deployMin = -10

--- @param o Object
function bhv_viewmodel_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.12)

    o.hitboxRadius = 0
    o.hitboxHeight = 0

    local m = gMarioStates[0]
    o.oPosY = m.pos.y + deployHeight
end

timer = 0
increment = 0.07
--- @param o Object
function bhv_viewmodel_loop(o)
    timer = timer + increment
    local m = gMarioStates[0]
    if m.forwardVel < 20 then
        increment = 0.02
    elseif m.forwardVel > 20 then
        increment = 0.07
    elseif m.forwardVel > 30 then
        increment = 0.08
    elseif m.forwardVel > 50 then
        increment = 0.09
    elseif m.forwardVel > 70 then
        increment = 0.1
    end

    o.oPosX = gLakituState.focus.x + (1970 * math.sin(gLakituState.yaw / 0x8000 * math.pi))
    local y = m.pos.y + (clamp(yOffset, DEGREES(-90), DEGREES(360)) / 40)
    if (m.action & ACT_FLAG_SHORT_HITBOX) == 0 then
        o.oPosY = y + deployHeight + 3 * math.sin(timer)
    else
        o.oPosY = y + deployHeight - (heightMoving / 2) + 3 * math.sin(timer)
    end
    o.oPosZ = gLakituState.focus.z + (1970 * math.cos(gLakituState.yaw / 0x8000 * math.pi))

    o.oFaceAnglePitch = 0
    o.oFaceAngleYaw = gLakituState.yaw - 0x4000
    local dy = m.area.camera.focus.y - m.area.camera.pos.y
    o.oFaceAngleRoll = -4 * dy

    if deployHeight < deployMax then
        deployHeight = deployHeight + 5
    end

    -- if obj_has_model_extended(o, gunTable[gPlayerSyncTable[0].gun].arm) or obj_has_model_extended(o, gunTable[gPlayerSyncTable[0].gun].metalArm) then
    --     if (m.flags & MARIO_VANISH_CAP) ~= 0 then
    --         o.activeFlags = o.activeFlags | ACTIVE_FLAG_DITHERED_ALPHA
    --     else
    --         o.activeFlags = o.activeFlags & ACTIVE_FLAG_ACTIVE
    --     end
    -- end
end
id_bhvViewModel = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_viewmodel_init, bhv_viewmodel_loop)

function spawn_arm()
    if arm == nil then
        local localGun = gPlayerSyncTable[0].gun
        deployHeight = deployMin
        arm = spawn_non_sync_object(
            id_bhvViewModel,
            get_arm_state(localGun),
            gLakituState.focus.x + (1970 * math.sin(gLakituState.yaw / 0x8000 * math.pi)),
            -11000,
            gLakituState.focus.z + (1970 * math.cos(gLakituState.yaw / 0x8000 * math.pi)),
            --- @param o Object
            function (o)
                o.oFaceAnglePitch = 0
                o.oFaceAngleYaw = gLakituState.yaw - 0x4000
                o.oFaceAngleRoll = 0
            end
        )
        vgun = spawn_non_sync_object(
            id_bhvViewModel,
            gunTable[localGun].vmodel,
            gLakituState.focus.x + (1970 * math.sin(gLakituState.yaw / 0x8000 * math.pi)),
            -11000,
            gLakituState.focus.z + (1970 * math.cos(gLakituState.yaw / 0x8000 * math.pi)),
            --- @param o Object
            function (o)
                o.oFaceAnglePitch = 0
                o.oFaceAngleYaw = gLakituState.yaw - 0x4000
                o.oFaceAngleRoll = 0
            end
        )
    end
end

function despawn_arm()
    if arm ~= nil then
        obj_mark_for_deletion(arm)
        arm = nil
        obj_mark_for_deletion(vgun)
        vgun = nil
    end
end

function get_arm_state(gun)
    if gPlayerSyncTable[0].metalCap then
        return gunTable[gun].metalArm
    end
    if gPlayerSyncTable[0].modelId == E_MODEL_GORDON then
        return gunTable[gun].gordonArm
    end
    return gunTable[gun].arm
end