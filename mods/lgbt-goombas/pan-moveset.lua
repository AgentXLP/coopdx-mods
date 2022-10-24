function s16(num)
    num = math.floor(num) & 0xFFFF
    if num >= 32768 then return num - 65536 end
    return num
end

--- @param m MarioState
function act_roll(m)
    m.particleFlags = m.particleFlags | PARTICLE_DUST

    m.faceAngle.y = s16(m.intendedYaw - approach_s32(s16(m.intendedYaw - m.faceAngle.y), 0, 0x400, 0x400))
    if m.area.terrainType ~= TERRAIN_SNOW and m.area.terrainType ~= TERRAIN_SLIDE then
        mario_set_forward_vel(m, m.forwardVel - 0.4)
    else
        mario_set_forward_vel(m, 90)
    end

    if (m.input & INPUT_A_PRESSED) ~= 0 or (m.input & INPUT_B_PRESSED) ~= 0 then return set_jumping_action(m, ACT_FORWARD_ROLLOUT, 0) end
    if m.forwardVel < 25 then set_mario_action(m, ACT_DIVE_SLIDE, 0) end
    if (m.input & INPUT_Z_PRESSED) ~= 0 then return set_mario_action(m, ACT_CROUCH_SLIDE, 0) end

    common_slide_action(m, ACT_CROUCH_SLIDE, ACT_FREEFALL, MARIO_ANIM_FORWARD_SPINNING)
end

ACT_ROLL = allocate_mario_action(ACT_GROUP_MOVING | ACT_FLAG_MOVING | ACT_FLAG_ATTACKING | ACT_FLAG_SHORT_HITBOX | ACT_FLAG_BUTT_OR_STOMACH_SLIDE)

--- @param m MarioState
function before_pan_phys_step(m)
    if m.action ~= ACT_ROLL then
        if m.area.terrainType == TERRAIN_SNOW then
            m.peakHeight = m.pos.y
            m.vel.x = m.vel.x * 1.5
            m.vel.z = m.vel.z * 1.5
        else
            if m.area.terrainType == TERRAIN_SLIDE then m.peakHeight = m.pos.y end
            m.vel.x = m.vel.x * 1.25
            m.vel.z = m.vel.z * 1.25
        end
    end

    if m.action == ACT_SLIDE_KICK or m.action == ACT_SLIDE_KICK_SLIDE then
        set_mario_action(m, ACT_ROLL, 0)
        mario_set_forward_vel(m, 80)
    end

    if m.action == ACT_WALL_KICK_AIR then m.peakHeight = m.pos.y end

    if (m.action & ACT_FLAG_AIR) ~= 0 then
        m.vel.y = m.vel.y - 0.4
    elseif m.action == ACT_WALKING and m.forwardVel > 0 then
        m.faceAngle.y = m.intendedYaw
    end
end

hook_mario_action(ACT_ROLL, act_roll, INTERACT_DAMAGE)