--- @param m MarioState
function act_spin_jump(m)
    set_mario_animation(m, MARIO_ANIM_TWIRL)
    m.angleVel.y = m.angleVel.y - 0x1000
    m.vel.y = 10
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES
    if m.actionTimer == 0 then
        play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
    elseif m.actionTimer > 15 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end
    m.actionTimer = m.actionTimer + 1
    m.pos.y = m.pos.y + math.sin(m.actionTimer * 0.5) * 5

    update_air_with_turn(m)
    switch(perform_air_step(m, 0), {
        [AIR_STEP_LANDED] = function()
            set_mario_action(m, ACT_DECELERATING, 0)
        end,
        [AIR_STEP_HIT_WALL] = function()
            if (m.input & INPUT_A_PRESSED) ~= 0 then
                set_mario_action(m, ACT_WALL_KICK_AIR, 0)
                play_sound(SOUND_ACTION_BONK, m.marioObj.header.gfx.cameraToObject)
                m.faceAngle.y = m.faceAngle.y + 0x8000
            end
        end,
        [AIR_STEP_HIT_LAVA_WALL] = function()
            lava_boost_on_wall(m)
        end
    })

    m.marioObj.header.gfx.angle.y = m.marioObj.header.gfx.angle.y + m.angleVel.y
end

ACT_SPIN_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_MOVING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION | ACT_FLAG_ATTACKING)

--- @param m MarioState
function update_bi_air_with_turn(m)
    local dragThreshold
    local intendedDYaw
    local intendedMag

    if check_horizontal_wind(m) == 0 then
        dragThreshold = if_then_else(m.action == ACT_LONG_JUMP, 48, 32)
        m.forwardVel = approach_number(m.forwardVel, 0, 0.35, 0.35)

        if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
            intendedDYaw = m.intendedYaw - m.faceAngle.y
            if intendedDYaw > 32767 then intendedDYaw = intendedDYaw - 65536 end
            if intendedDYaw < -32768 then intendedDYaw = intendedDYaw + 65536 end
            intendedMag = m.intendedMag / 32

            m.forwardVel = m.forwardVel + 1.5 * coss(intendedDYaw) * intendedMag
            m.faceAngle.y = m.faceAngle.y + math.floor(1024 * sins(intendedDYaw) * intendedMag)
        end

        --! Uncapped air speed. Net positive when moving forward.
        if m.forwardVel > dragThreshold then
            m.forwardVel = m.forwardVel - 1
        end
        if m.forwardVel < -16 then
            m.forwardVel = m.forwardVel + 2
        end

        m.slideVelX = m.forwardVel * sins(m.faceAngle.y)
        m.slideVelZ = m.forwardVel * coss(m.faceAngle.y)
        m.vel.x = m.slideVelX
        m.vel.z = m.slideVelZ
    end
end

canSpinJump = true

--- @param m MarioState
function before_bi_phys_step(m)
    if m.action == ACT_TWIRLING and (m.input & INPUT_Z_DOWN) ~= 0 then m.vel.y = m.vel.y - 50 end

    if m.wall ~= nil and (m.action & ACT_FLAG_AIR) ~= 0 then m.controller.buttonDown = m.controller.buttonDown & ~A_BUTTON end

    if m.forwardVel > 5 and (m.action & ACT_FLAG_AIR) ~= 0 then update_bi_air_with_turn(m) end

    if m.playerIndex == 0 then
        if m.pos.y <= m.floorHeight then canSpinJump = true end
        if (m.action == ACT_LONG_JUMP or m.action == ACT_JUMP_KICK or m.action == ACT_DIVE) and (m.input & INPUT_B_PRESSED) ~= 0 and canSpinJump then
            canSpinJump = false
            set_mario_action(m, ACT_SPIN_JUMP, 0)
        end
    end
    if m.action == ACT_TRIPLE_JUMP then set_mario_action(m, ACT_DOUBLE_JUMP, 0) end

    if (m.action & ACT_FLAG_SWIMMING) ~= 0 then
        m.vel.x = m.vel.x * 0.7
        m.vel.z = m.vel.z * 0.7
    else
        m.vel.x = m.vel.x * 1.25
        m.vel.z = m.vel.z * 1.25
    end
end

hook_mario_action(ACT_SPIN_JUMP, act_spin_jump, INTERACT_DAMAGE)