MAX_POWER_JUMP_HEIGHT = 150

--- @param m MarioState
function act_custom_triple_jump(m)
    if (m.input & INPUT_B_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_DIVE, 0)
    end

    if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    play_mario_sound(m, SOUND_ACTION_TERRAIN_JUMP, CHAR_SOUND_YAHOO)

    common_air_action_step(m, ACT_TRIPLE_JUMP_LAND, MARIO_ANIM_FORWARD_SPINNING, 0)

    if m.vel.y < -20 then set_mario_action(m, ACT_TWIRLING, 0) end

    if m.actionState == 0 or m.vel.y > 0 then
        if set_mario_animation(m, MARIO_ANIM_FORWARD_SPINNING) == 0 then
            play_sound(SOUND_ACTION_SPIN, m.marioObj.header.gfx.cameraToObject)
        end
    end

    set_mario_particle_flags(m, PARTICLE_SPARKLES, 0)
end

--- @param m MarioState
function act_power_jump(m)
    set_mario_animation(m, MARIO_ANIM_CROUCHING)
    m.particleFlags = m.particleFlags | PARTICLE_SPARKLES

    if m.actionTimer % 35 == 0 then
        play_sound(SOUND_GENERAL_COIN_SPURT, m.marioObj.header.gfx.cameraToObject)
    end
    m.actionTimer = m.actionTimer + 1

    if (m.controller.buttonDown & Z_TRIG) ~= 0 and ((m.controller.buttonDown & Y_BUTTON) ~= 0 or (m.controller.buttonDown & X_BUTTON) ~= 0) then
        m.vel.y = m.vel.y + 1
        if m.vel.y == MAX_POWER_JUMP_HEIGHT - 1 then spawn_orange_number(MAX_POWER_JUMP_HEIGHT, 0, 0, 0) end

        if m.vel.y > MAX_POWER_JUMP_HEIGHT then m.vel.y = MAX_POWER_JUMP_HEIGHT end
        if obj_get_first_with_behavior_id(id_bhvOrangeNumber) == nil then
            if m.vel.y < MAX_POWER_JUMP_HEIGHT then
                spawn_orange_number(math.floor(m.vel.y), 0, 0, 0)
            end
        end
    else
        if m.vel.y > 10 then
            m.pos.y = m.pos.y + 10
            return set_mario_action(m, ACT_CUSTOM_TRIPLE_JUMP, 0)
        else
            m.vel.y = 0
            return set_mario_action(m, ACT_STOP_CROUCHING, 0)
        end
    end
    stationary_ground_step(m)
end

ACT_CUSTOM_TRIPLE_JUMP = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)
ACT_POWER_JUMP = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_STATIONARY | ACT_FLAG_SHORT_HITBOX)

--- @param m MarioState
function before_asexual_phys_step(m)
    if (m.action & ACT_FLAG_AIR) ~= 0 then m.vel.y = m.vel.y + 0.3 end
    if m.action == ACT_GROUND_POUND then m.vel.y = -120 end
    m.peakHeight = m.pos.y

    if m.action == ACT_TWIRLING and (m.input & INPUT_Z_DOWN) ~= 0 then m.vel.y = m.vel.y - 50 end
end

hook_mario_action(ACT_CUSTOM_TRIPLE_JUMP, act_custom_triple_jump, INTERACT_PLAYER)
hook_mario_action(ACT_POWER_JUMP, act_power_jump, INTERACT_PLAYER)