-- ______ _          __     _____
-- |  ____(_)        | |   |  __ \
-- | |__   _ _ __ ___| |_  | |__) |__ _ __ ___  ___  _ __
-- |  __| | | '__/ __| __| |  ___/ _ \ '__/ __|/ _ \| '_ \
-- | |    | | |  \__ \ |_  | |  |  __/ |  \__ \ (_) | | | |
-- |_|    |_|_|  |___/\__| |_|   \___|_|  |___/\___/|_| |_|
-- By Agent X and PeachyPeach
MARIO_HEAD_POS = 120

gGlobalSyncTable.bhop = true
gGlobalSyncTable.autoBh = true

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

--- @param m MarioState
function update_fp_camera(m)
    local sensX = 0.3 * camera_config_get_x_sensitivity()
    local sensY = 0.4 * camera_config_get_y_sensitivity()
    local invX = if_then_else(camera_config_is_x_inverted(), 1, -1)
    local invY = if_then_else(camera_config_is_y_inverted(), 1, -1)

    -- check cancels
    if (m.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE or
        m.action == ACT_FIRST_PERSON or
        m.action == ACT_DROWNING or
        m.action == ACT_WATER_DEATH or
        m.action == ACT_GRABBED or
        m.action == ACT_IN_CANNON or
        m.action == ACT_TORNADO_TWIRLING or
        m.action == ACT_BUBBLED then
        disable_fp()
        return
    end

    -- update pitch
    sPlayerFirstPerson.pitch = sPlayerFirstPerson.pitch - sensY * (invY * m.controller.extStickY - 1.5 * djui_hud_get_raw_mouse_y())
    sPlayerFirstPerson.pitch = clamp(sPlayerFirstPerson.pitch, -0x3F00, 0x3F00)

    -- update yaw
    if (m.controller.buttonPressed & L_TRIG) ~= 0 then sPlayerFirstPerson.yaw = m.faceAngle.y + 0x8000
    else sPlayerFirstPerson.yaw = sPlayerFirstPerson.yaw + sensX * (invX * m.controller.extStickX - 1.5 * djui_hud_get_raw_mouse_x()) end
    sPlayerFirstPerson.yaw = (sPlayerFirstPerson.yaw + 0x10000) % 0x10000

    -- fix yaw for some specific actions
    -- if the left stick is held, use Mario's yaw to set the camera's yaw
    -- otherwise, set Mario's yaw to the camera's yaw
    for _, flag in ipairs({ ACT_FLYING, ACT_HOLDING_BOWSER, ACT_FLAG_ON_POLE, ACT_FLAG_SWIMMING }) do
        if (m.action & flag) == flag then
            if math.abs(m.controller.stickX) > 4 then sPlayerFirstPerson.yaw = m.faceAngle.y + 0x8000
            else m.faceAngle.y = sPlayerFirstPerson.yaw - 0x8000 end
            break
        end
    end
    gLakituState.yaw = sPlayerFirstPerson.yaw
    m.area.camera.yaw = sPlayerFirstPerson.yaw

    -- update pos
    local y = m.marioBodyState.headPos.y + 35
    if (m.action & ACT_FLAG_AIR) ~= 0 then
        y = m.pos.y + MARIO_HEAD_POS
    end

    gLakituState.pos.x = m.pos.x + coss(sPlayerFirstPerson.pitch) * sins(sPlayerFirstPerson.yaw)
    gLakituState.pos.y = y + sins(sPlayerFirstPerson.pitch)
    gLakituState.pos.z = m.pos.z + coss(sPlayerFirstPerson.pitch) * coss(sPlayerFirstPerson.yaw)
    vec3f_copy(m.area.camera.pos, gLakituState.pos)
    vec3f_copy(gLakituState.curPos, gLakituState.pos)
    vec3f_copy(gLakituState.goalPos, gLakituState.pos)

    -- update focus
    gLakituState.focus.x = m.pos.x - 100 * coss(sPlayerFirstPerson.pitch) * sins(sPlayerFirstPerson.yaw)
    gLakituState.focus.y = y - 100 * sins(sPlayerFirstPerson.pitch)
    gLakituState.focus.z = m.pos.z - 100 * coss(sPlayerFirstPerson.pitch) * coss(sPlayerFirstPerson.yaw)
    vec3f_copy(m.area.camera.focus, gLakituState.focus)
    vec3f_copy(gLakituState.curFocus, gLakituState.focus)
    vec3f_copy(gLakituState.goalFocus, gLakituState.focus)

    -- set other values
    gLakituState.posHSpeed = 0
    gLakituState.posVSpeed = 0
    gLakituState.focHSpeed = 0
    gLakituState.focVSpeed = 0
    m.marioBodyState.modelState = 0x100
end

--- @param m MarioState
function handle_fp(m)
    if gNetworkPlayers[0].currActNum == 99 then disable_fp() end

    djui_hud_set_mouse_locked(true)
    update_fp_camera(m)

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
    sPlayerFirstPerson.freecam = camera_config_is_free_cam_enabled()
    camera_freeze()
    set_override_near(45)
    sPlayerFirstPerson.enabled = true
    sPlayerFirstPerson.pitch = 0
    sPlayerFirstPerson.yaw = gMarioStates[0].faceAngle.y + 0x8000
end

function disable_fp()
    camera_config_enable_free_cam(sPlayerFirstPerson.freecam)
    camera_unfreeze()
    set_override_near(0)
    sPlayerFirstPerson.enabled = false
    sPlayerFirstPerson.pitch = 0
    sPlayerFirstPerson.yaw = 0
end

function reset_fp()
    if sPlayerFirstPerson.enabled then
        disable_fp()
        enable_fp()
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

bhGain = 1
bhTimer = 0
--- @param m MarioState
function mario_update(m)
    if m.playerIndex == 0 then
        -- first person
        if sPlayerFirstPerson.enabled then
            gLakituState.mode = CAMERA_MODE_FREE_ROAM
            gLakituState.defMode = CAMERA_MODE_FREE_ROAM
        elseif camera_config_is_free_cam_enabled() then
            gLakituState.mode = CAMERA_MODE_NEWCAM
            gLakituState.defMode = CAMERA_MODE_NEWCAM
        elseif gLakituState.mode == CAMERA_MODE_NEWCAM or gLakituState.defMode == CAMERA_MODE_NEWCAM then
            gLakituState.mode = CAMERA_MODE_FREE_ROAM
            gLakituState.defMode = CAMERA_MODE_FREE_ROAM
        end

        -- secondary
        if not sPlayerFirstPerson.enabled then
            if not camera_config_is_mouse_look_enabled() then
                djui_hud_set_mouse_locked(false)
                bhGain = 1
            end
        else
            handle_fp(m)
        end
    end
end

--- @param m MarioState
function on_set_mario_action(m)
    if m.playerIndex ~= 0 then return end
    if (m.prevAction == ACT_IN_CANNON or m.prevAction == ACT_BUBBLED or (m.prevAction & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE) and fpCommandEnabled then
        enable_fp()
    end

    if gGlobalSyncTable.bhop == false then return end
    if sPlayerFirstPerson.enabled and m.forwardVel > 20 and (m.action & ACT_FLAG_AIR) ~= 0 then
        bhGain = bhGain + 0.12
    end
    bhTimer = 0
end

--- @param m MarioState
function mario_before_phys_step(m)
    if m.playerIndex ~= 0 then return end
    if gGlobalSyncTable.bhop == false then return end
    if sPlayerFirstPerson.enabled then
        -- auto bh
        if gGlobalSyncTable.autoBh and (m.flags & MARIO_WING_CAP) == 0 and mario_floor_is_steep(m) == 0 then
            if (m.controller.buttonDown & A_BUTTON) ~= 0 and (m.action & ACT_GROUP_MASK) == ACT_GROUP_MOVING then
                m.vel.y = STATIC_JUMP_HEIGHT
                set_mario_action(m, ACT_STATIC_JUMP, 0)
            end
        end

        if m.forwardVel <= 0 then bhGain = 1 end
        if bhGain > 1.2 then m.faceAngle.y = sPlayerFirstPerson.yaw + 0x8000 end

        if (m.action & ACT_FLAG_AIR) ~= 0 or (m.action & ACT_FLAG_MOVING) ~= 0 then
            m.vel.x = m.vel.x * bhGain
            m.vel.z = m.vel.z * bhGain
        end
    end
end

--- @param m MarioState
function before_mario_update(m)
    if m.playerIndex ~= 0 then return end
    if m.action == ACT_IN_CANNON or
    m.action == ACT_BUBBLED or
    m.action == ACT_READING_AUTOMATIC_DIALOG or
    m.action == ACT_READING_NPC_DIALOG then disable_fp() end
    if gGlobalSyncTable.bhop == false then return end
    if not sPlayerFirstPerson.enabled then return end

    if m.action == ACT_JUMP and (m.flags & MARIO_WING_CAP) == 0 then
        m.vel.y = STATIC_JUMP_HEIGHT
        set_mario_action(m, ACT_STATIC_JUMP, 0)
    end
    if m.action == ACT_DOUBLE_JUMP and (m.flags & MARIO_WING_CAP) == 0 then
        m.vel.y = STATIC_JUMP_HEIGHT
        set_mario_action(m, ACT_STATIC_JUMP, 0)
    end
end

function on_warp()
    reset_fp()
    if sPlayerFirstPerson.enabled then
        gLakituState.yaw = gMarioStates[0].faceAngle.y + 0x8000
    end
    yOffset = 0
    totwcTimer = 0
end

hook_mario_action(ACT_STATIC_JUMP, act_static_jump)

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_BEFORE_PHYS_STEP, mario_before_phys_step)
hook_event(HOOK_BEFORE_MARIO_UPDATE, before_mario_update)
hook_event(HOOK_ON_WARP, on_warp)