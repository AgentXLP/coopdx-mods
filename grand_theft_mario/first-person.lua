gGlobalSyncTable.bhop = true
gGlobalSyncTable.autoBh = true

firstPerson = false
heightMoving = 135
yOffset = 0
local yawOffset = 0
sensitivity = 5
sensitivityY = 1

arm = nil

function clamp(v, min, max)
    if v < min then return min end
    if v > max then return max end
    return v
end

function DEGREES(degree)
    return (degree * 0x1000 / 360)
end
function TO_DEGREES(degree)
    return (degree * 360 / 0x1000)
end

--- @param m MarioState
function update_fp_camera(m)
    -- handle inputs
    if m.controller.extStickX == 0 then
        yawOffset = yawOffset + -1 * djui_hud_get_raw_mouse_x()
    else
        yawOffset = yawOffset - m.controller.extStickX
    end
    yawOffset = yawOffset * sensitivity

    if m.controller.extStickY == 0 then
        yOffset = yOffset + (-0.9 * sensitivityY) * djui_hud_get_raw_mouse_y()
    else
        yOffset = yOffset + m.controller.extStickY * sensitivityY
    end
    yOffset = clamp(yOffset, DEGREES(-360), DEGREES(360))

    if m.floor.type == SURFACE_LOOK_UP_WARP and yOffset > DEGREES(180) then -- QoL
        totwc_warp()
    end
    -- initiate
    gLakituState.posHSpeed = 0.0
    gLakituState.focHSpeed = 0.0
    if m.action ~= ACT_DISAPPEARED then
        gLakituState.yaw = gLakituState.yaw + yawOffset
    end
    if (m.action & ACT_FLAG_ON_POLE) ~= 0 then
        gLakituState.yaw = m.faceAngle.y
    elseif (m.action & ACT_FLAG_SWIMMING) ~= 0 then
        gLakituState.yaw = m.faceAngle.y + 0x8000
    end
    yawOffset = 0
    -- lock in the position
    gLakituState.pos.x = m.pos.x
    if (m.action & ACT_FLAG_SHORT_HITBOX) ~= 0 then
        gLakituState.pos.y = m.pos.y + (heightMoving / 2) + 6 * math.sin(timer)
    else
        gLakituState.pos.y = m.pos.y + heightMoving + 6 * math.sin(timer)
    end
    if m.health <= 0xff and gLakituState.pos.y > m.floorHeight then
        gLakituState.pos.y = gLakituState.pos.y - 1
    end
    gLakituState.pos.z = m.pos.z
    -- fix pos
    gLakituState.pos.x = gLakituState.pos.x + (8 * math.sin(gLakituState.yaw / 0x8000 * math.pi))
    gLakituState.pos.z = gLakituState.pos.z + (8 * math.cos(gLakituState.yaw / 0x8000 * math.pi))
    -- copy pos to curPos and goalPos
    gLakituState.curPos.x = gLakituState.pos.x
    gLakituState.curPos.y = gLakituState.pos.y
    gLakituState.curPos.z = gLakituState.pos.z
    gLakituState.goalPos.x = gLakituState.pos.x
    gLakituState.goalPos.y = gLakituState.pos.y
    gLakituState.goalPos.z = gLakituState.pos.z
    -- focus
    gLakituState.focus.x = gLakituState.pos.x
    gLakituState.focus.y = gLakituState.pos.y
    gLakituState.focus.z = gLakituState.pos.z
    gLakituState.focus.x = gLakituState.focus.x - (2048 * math.sin(gLakituState.yaw / 0x8000 * math.pi))
    gLakituState.focus.y = gLakituState.focus.y + yOffset
    gLakituState.focus.z = gLakituState.focus.z - (2048 * math.cos(gLakituState.yaw / 0x8000 * math.pi))
    -- copy focus to curFocus and goalFocus to attempt to prevent the lerping with vertical look
    gLakituState.curFocus.x = gLakituState.focus.x
    gLakituState.curFocus.y = gLakituState.focus.y
    gLakituState.curFocus.z = gLakituState.focus.z
    gLakituState.goalFocus.x = gLakituState.goalFocus.x
    gLakituState.goalFocus.y = gLakituState.goalFocus.y
    gLakituState.goalFocus.z = gLakituState.goalFocus.z
    -- area camera position
    m.area.camera.pos.x = gLakituState.pos.x
    m.area.camera.pos.y = gLakituState.pos.y
    m.area.camera.pos.z = gLakituState.pos.z
    -- area camera focus
    m.area.camera.focus.x = gLakituState.focus.x
    m.area.camera.focus.y = gLakituState.focus.y
    m.area.camera.focus.z = gLakituState.focus.z
    -- area camera yaw
    m.area.camera.yaw = gLakituState.yaw

    obj_set_model_extended(gMarioStates[0].marioObj, E_MODEL_NONE)

    if m.action == ACT_IN_CANNON or m.action == ACT_BUBBLED then
        disable_fp()
    end
end

--- @param m MarioState
function handle_first_person(m)
    update_fp_camera(m)
    if m.controller.stickX == 0 and m.controller.stickY > 0 and (m.action & ACT_FLAG_AIR) == 0 and (m.action & ACT_FLAG_SWIMMING) == 0 and
    m.action ~= ACT_LEDGE_GRAB and m.action ~= ACT_LEDGE_CLIMB_FAST and m.action ~= ACT_LEDGE_CLIMB_SLOW_1 and m.action ~= ACT_LEDGE_CLIMB_SLOW_2 then
        m.faceAngle.y = gLakituState.yaw + 0x8000
    end
    if m.action == ACT_STATIC_JUMP and bhGain > 1.2 then m.faceAngle.y = gLakituState.yaw + 0x8000 end

    djui_hud_set_mouse_locked(true)

    if gGlobalSyncTable.bhop == false then return end
    if (m.action & ACT_FLAG_MOVING) ~= 0 and bhTimer < 5 then bhTimer = bhTimer + 1 end

    if bhGain > 1 then
        if (m.action & ACT_FLAG_STATIONARY) ~= 0 or ((m.action & ACT_FLAG_MOVING) ~= 0 and bhTimer == 5) or ((m.action & ACT_FLAG_AIR) ~= 0 and m.action ~= ACT_STATIC_JUMP and m.action ~= ACT_DOUBLE_JUMP) then
            bhGain = bhGain - 1
        elseif (m.action & ACT_FLAG_MOVING) ~= 0 then
            bhGain = bhGain - 0.01
        end
    end

    -- fail safe
    if bhGain < 1 then bhGain = 1 end
end

function enable_fp()
    firstPerson = true
    if arm == nil and gun ~= nil then
        spawn_arm()
    end
    camera_freeze()
    hud_hide()
    set_override_near(45)
end

function disable_fp()
    firstPerson = false
    despawn_arm()
    camera_unfreeze()
    hud_show()
    set_override_near(0)
    set_override_fov(0)
end

function on_arm_changed(tag, oldVal, newVal)
    if oldVal == newVal then return end
    gun_change(gMarioStates[0], gPlayerSyncTable[0].gun)
end

-- easter egg level
function on_level_init()
    if gNetworkPlayers[0].currLevelNum == LEVEL_SA then
        showTitle = true
        play_sound(SOUND_GENERAL_LOUD_POUND2, gMarioStates[0].marioObj.header.gfx.cameraToObject)
    end
end

bhGain = 1
bhTimer = 0
--- @param m MarioState
function on_set_mario_action(m)
    if m.playerIndex ~= 0 then return end
    if (m.prevAction == ACT_IN_CANNON or m.action == ACT_BUBBLED) and fpCommandEnabled then
        enable_fp()
        gLakituState.yaw = m.faceAngle.y - 0x8000
    end

    if gGlobalSyncTable.bhop == false then return end
    if firstPerson and m.forwardVel > 20 and (m.action & ACT_FLAG_AIR) ~= 0 then
        bhGain = bhGain + 0.12
    end
    bhTimer = 0
end

--- @param m MarioState
function mario_before_phys_step(m)
    if m.playerIndex ~= 0 then return end
    if gGlobalSyncTable.bhop == false then return end
    if firstPerson then
        -- if bhGain >= 1.2 then m.faceAngle.y = m.intendedYaw end

        -- auto bh
        if gGlobalSyncTable.autoBh and (m.flags & MARIO_WING_CAP) == 0 then
            if (m.controller.buttonDown & A_BUTTON) ~= 0 and (m.action & ACT_GROUP_MASK) == ACT_GROUP_MOVING then
                m.vel.y = STATIC_JUMP_HEIGHT
                set_mario_action(m, ACT_STATIC_JUMP, 0)
            end
        end

        if m.forwardVel <= 0 then bhGain = 1 end

        if (m.action & ACT_FLAG_AIR) ~= 0 or (m.action & ACT_FLAG_MOVING) ~= 0 then
            m.vel.x = m.vel.x * bhGain
            m.vel.z = m.vel.z * bhGain
        end
    end
end

--- @param m MarioState
function before_mario_update(m)
    if m.playerIndex ~= 0 then return end
    if gGlobalSyncTable.bhop == false then return end
    if firstPerson == false then return end

    if m.action == ACT_JUMP and (m.flags & MARIO_WING_CAP) == 0 then
        m.vel.y = STATIC_JUMP_HEIGHT
        set_mario_action(m, ACT_STATIC_JUMP, 0)
    end
    if m.action == ACT_DOUBLE_JUMP and (m.flags & MARIO_WING_CAP) == 0 then
        m.vel.y = STATIC_JUMP_HEIGHT
        set_mario_action(m, ACT_STATIC_JUMP, 0)
    end
end

STATIC_JUMP_HEIGHT = 30
ACT_STATIC_JUMP = allocate_mario_action(ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_CUSTOM_ACTION)
--- @param m MarioState
function act_static_jump(m)
    check_kick_or_dive_in_air(m)

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, 0)
    common_air_action_step(m, ACT_JUMP_LAND, MARIO_ANIM_SINGLE_JUMP,
                           AIR_STEP_CHECK_LEDGE_GRAB | AIR_STEP_CHECK_HANG)
    return false
end

--- @param m MarioState
function on_player_disconnected(m)
    if m.playerIndex == 0 then
        disable_fp()
    end
end

hook_mario_action(ACT_STATIC_JUMP, act_static_jump)

hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_BEFORE_PHYS_STEP, mario_before_phys_step)
hook_event(HOOK_BEFORE_MARIO_UPDATE, before_mario_update)

hook_on_sync_table_change(gPlayerSyncTable[0], "metalCap", 0, on_arm_changed)
hook_on_sync_table_change(gPlayerSyncTable[0], "modelId", 0, on_arm_changed)