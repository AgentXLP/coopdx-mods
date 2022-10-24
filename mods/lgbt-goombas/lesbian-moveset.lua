function DEGREES(x) return x * 0x10000 / 360 end

--- @param m MarioState
function swimming_near_surface(m)
    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        return false
    end

    return (m.waterLevel - 80) - m.pos.y < 400
end

--- @param m MarioState
function get_buoyancy(m)
    local buoyancy = 0

    if (m.flags & MARIO_METAL_CAP) ~= 0 then
        if (m.action & ACT_FLAG_INVULNERABLE) ~= 0 then
            buoyancy = -2
        else
            buoyancy = -18
        end
    elseif swimming_near_surface(m) then
        buoyancy = 1.25
    elseif (m.action & ACT_FLAG_MOVING) == 0 then
        buoyancy = -2
    end

    return buoyancy
end

--- @param m MarioState
function update_swimming_speed(m, decelThreshold)
    local buoyancy = get_buoyancy(m)
    local maxSpeed = 28

    if (m.action & ACT_FLAG_STATIONARY) ~= 0 then m.forwardVel = m.forwardVel - 2 end

    if m.forwardVel < 0 then m.forwardVel = 0 end

    if m.forwardVel > maxSpeed then m.forwardVel = maxSpeed end

    if (m.forwardVel > decelThreshold) then m.forwardVel = m.forwardVel - 0.5 end

    m.vel.x = m.forwardVel * coss(m.faceAngle.x) * sins(m.faceAngle.y)
    m.vel.y = m.forwardVel * sins(m.faceAngle.x) + buoyancy
    m.vel.z = m.forwardVel * coss(m.faceAngle.x) * coss(m.faceAngle.y)
end

--- @param m MarioState
function update_swimming_pitch(m)
    local targetPitch = -(252 * m.controller.stickY)

    local pitchVel
    if m.faceAngle.x < 0 then
        pitchVel = 0x100
    else
        pitchVel = 0x200
    end

    if m.faceAngle.x < targetPitch then
        m.faceAngle.x = m.faceAngle.x + pitchVel
        if m.faceAngle.x > targetPitch then
            m.faceAngle.x = targetPitch
        end
    elseif m.faceAngle.x > targetPitch then
        m.faceAngle.x = m.faceAngle.x - pitchVel
        if m.faceAngle.x < targetPitch then
            m.faceAngle.x = targetPitch
        end
    end
end

--- @param m MarioState
function update_swimming_yaw(m)
    local targetYawVel = -(10 * m.controller.stickX)

    if targetYawVel > 0 then
        if m.angleVel.y < 0 then
            m.angleVel.y = m.angleVel.y + 0x40
            if m.angleVel.y > 0x10 then m.angleVel.y = 0x10 end
        else
            m.angleVel.y = approach_s32(m.angleVel.y, targetYawVel, 0x10, 0x20)
        end
    elseif targetYawVel < 0 then
        if m.angleVel.y > 0 then
            m.angleVel.y = m.angleVel.y - 0x40
            if m.angleVel.y < -0x10 then m.angleVel.y = -0x10 end
        else
            m.angleVel.y = approach_s32(m.angleVel.y, targetYawVel, 0x20, 0x10)
        end
    else
        m.angleVel.y = approach_s32(m.angleVel.y, 0, 0x40, 0x40)
    end

    m.faceAngle.y = m.faceAngle.y + m.angleVel.y
    -- m.faceAngle.z = -m.angleVel.y * 8
end

--- @param m MarioState
function do_improved_water_jump(m)
    drop_and_set_mario_action(m, ACT_JUMP, 0)
    m.vel.y = 70
    set_camera_mode(m.area.camera, m.area.camera.defMode, 1)
    return 1
end

--- @param m MarioState
function act_water_spin(m)
    if m.actionTimer >= 30 then return set_mario_action(m, ACT_WATER_IDLE, 0) end
    if (m.input & INPUT_A_PRESSED) ~= 0 and m.waterLevel - m.pos.y < 100 then return do_improved_water_jump(m) end

    if m.actionTimer % 5 == 0 then play_sound(SOUND_ACTION_TWIRL, m.marioObj.header.gfx.cameraToObject) end

    m.faceAngle.z = m.faceAngle.z + DEGREES(45)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

    m.vel.x = sins(m.faceAngle.y) * 70
    m.vel.z = coss(m.faceAngle.y) * 70
    m.forwardVel = vec3f_length(m.vel)
    update_swimming_pitch(m)
    update_swimming_yaw(m)
    perform_water_step(m)

    m.actionTimer = m.actionTimer + 1
end

ACT_WATER_SPIN = allocate_mario_action(ACT_GROUP_SUBMERGED | ACT_FLAG_SWIMMING | ACT_FLAG_SWIMMING_OR_FLYING | ACT_FLAG_ATTACKING)

--- @param m MarioState
function before_lesbian_phys_step(m)
    if m.action == ACT_WATER_DEATH then return end
    local multiplier = 1.2
    if m.terrainSoundAddend == 0x20000 and m.pos.y < m.waterLevel then multiplier = 1.5 end -- stepping in water

    if m.action == ACT_WATER_PUNCH or m.action == ACT_WATER_THROW then set_mario_action(m, ACT_WATER_SPIN, 0) end

    if m.action == ACT_WATER_JUMP or m.action == ACT_HOLD_WATER_JUMP then do_improved_water_jump(m) end

    if (m.action & ACT_FLAG_SWIMMING) ~= 0 then
        if m.action ~= ACT_WATER_SPIN and m.action ~= ACT_WATER_PUNCH and m.action ~= ACT_FORWARD_WATER_KB and m.action ~= ACT_BACKWARD_WATER_KB and m.action ~= ACT_WATER_SHOCKED then
            multiplier = 2.5
        end
    end

    m.vel.x = m.vel.x * multiplier
    m.vel.z = m.vel.z * multiplier
end

hook_mario_action(ACT_WATER_SPIN, act_water_spin, INTERACT_DAMAGE)