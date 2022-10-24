--- @param m MarioState
function act_wall_climb(m)
    if (m.input & INPUT_Z_PRESSED) ~= 0 then set_mario_action(m, ACT_LEDGE_CLIMB_DOWN, 0) end

    set_mario_animation(m, MARIO_ANIM_SLOW_LONGJUMP)
    if is_anim_past_end(m) ~= 0 then
        m.marioObj.header.gfx.animInfo.animFrame = 0
        play_sound(SOUND_ACTION_HANGING_STEP, m.marioObj.header.gfx.cameraToObject)
    end

    m.vel.y = m.controller.stickY * 0.3

    perform_air_step(m, AIR_STEP_CHECK_LEDGE_GRAB)
end

ACT_WALL_CLIMB = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_MOVING)

--- @param m MarioState
function before_trans_phys_step(m)
    m.peakHeight = m.pos.y

    if m.action == ACT_JUMP or m.action == ACT_WALL_KICK_AIR then
        if m.action == ACT_WALL_KICK_AIR and m.prevAction == ACT_DIVE and m.actionTimer < 7 then
            m.vel.x = m.vel.x * 2.6
            m.vel.z = m.vel.z * 2.6
        end

        m.actionTimer = m.actionTimer + 1

        if jumpCount > 0 and m.actionTimer > 10 and (m.input & INPUT_A_PRESSED) ~= 0 then
            set_mario_action(m, ACT_DOUBLE_JUMP, 0)
            m.vel.y = m.vel.y + 10
            m.peakHeight = m.pos.y
            jumpCount = jumpCount - 1
        end
    elseif m.action == ACT_DIVE and m.prevAction ~= ACT_WALL_KICK_AIR then
        play_sound(SOUND_ACTION_FLYING_FAST, m.marioObj.header.gfx.cameraToObject)
        set_mario_action(m, ACT_WALL_KICK_AIR, 0)
    end


    local wall = collision_find_surface_on_ray(m.pos.x, m.pos.y + 60, m.pos.z, sins(m.faceAngle.y) * 60, 0, coss(m.faceAngle.y) * 60)
    if wall.surface ~= nil and (m.action & ACT_FLAG_AIR) ~= 0 and ((m.controller.buttonDown & X_BUTTON) ~= 0 or (m.controller.buttonDown & Y_BUTTON) ~= 0) then
        set_mario_action(m, ACT_WALL_CLIMB, 0)
        m.faceAngle.y = atan2s(wall.hitPos.z - m.pos.z, wall.hitPos.x - m.pos.x)
    elseif m.action == ACT_WALL_CLIMB then
        set_mario_action(m, ACT_FREEFALL, 0)
        m.vel.y = 35
    end

    if (m.input & INPUT_OFF_FLOOR) == 0 then jumpCount = 1 end

    m.vel.x = m.vel.x * 1.2
    m.vel.z = m.vel.z * 1.2
    m.slideVelX = m.slideVelX * 1.02
    m.slideVelZ = m.slideVelZ * 1.02
end

hook_mario_action(ACT_WALL_CLIMB, act_wall_climb, INTERACT_PLAYER)