--- @param m MarioState
function update_glider_with_turn(m)
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

            intendedMag = intendedMag * 3

            m.forwardVel = m.forwardVel + 1.5 * coss(intendedDYaw) * intendedMag
            m.faceAngle.y = m.faceAngle.y + math.floor(512 * sins(intendedDYaw) * intendedMag)
        end

        if m.forwardVel > (60 + if_then_else(m.vel.y < 0, 0, m.vel.y) * 0.6) then m.forwardVel = (60 + if_then_else(m.vel.y < 0, 0, m.vel.y) * 0.6) end

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

function glider_air_action_step(m, landAction, animation, stepArg)
    update_glider_with_turn(m)

    local stepResult = perform_air_step(m, stepArg)

    switch(stepResult, {
        [AIR_STEP_NONE] = function()
            set_mario_animation(m, animation)
        end,
        [AIR_STEP_LANDED] = function()
            set_mario_action(m, landAction, 0)
        end,
        [AIR_STEP_HIT_WALL] = function()
            set_mario_animation(m, animation)
            if m.forwardVel > 16 then
                mario_bonk_reflection(m, 0)
                m.faceAngle.y = m.faceAngle.y + 0x8000

                if m.wall then
                    set_mario_action(m, ACT_AIR_HIT_WALL, 0)
                else
                    if m.vel.y > 0 then m.vel.y = 0 end
                end
            else
                mario_set_forward_vel(m, 0.0)
            end
        end,
        [AIR_STEP_GRABBED_LEDGE] = function()
            set_mario_animation(m, MARIO_ANIM_IDLE_ON_LEDGE)
            drop_and_set_mario_action(m, ACT_LEDGE_GRAB, 0)
        end,
        [AIR_STEP_GRABBED_CEILING] = function()
            set_mario_action(m, ACT_START_HANGING, 0)
        end
    })

    return stepResult
end

--- @param m MarioState
function act_gliding(m)
	if (m.input & INPUT_Z_PRESSED) ~= 0 then
        return set_mario_action(m, ACT_GROUND_POUND, 0)
    end

    if (m.controller.buttonPressed & CUSTOM_BUTTON) ~= 0 and kartGliderCooldown == 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

	if m.vel.y < 0 and m.actionArg == 0 then
        m.actionArg = 1
    end

	if (m.input & INPUT_A_DOWN) ~= 0 and m.actionArg == 1 and m.vel.y < 0 then
        m.actionArg = 2
    end

	if (m.input & INPUT_A_DOWN) == 0 and m.actionArg == 2 then
		if m.vel.y < -35 then
            gPlayerSyncTable[m.playerIndex].targetGlider = (m.vel.y * -0.9)
            m.actionArg = 3
        end
    end
	if m.actionArg == 3 then
		if (m.vel.y + 16 >= gPlayerSyncTable[m.playerIndex].targetGlider) then
			m.vel.y = (gPlayerSyncTable[m.playerIndex].targetGlider - 2)
            m.actionArg = 1
		else
			m.vel.y = m.vel.y + 16
			m.vel.x = m.vel.x * 1.025
			m.vel.z = m.vel.z * 1.025
        end
    end

    glider_air_action_step(m, ACT_STOMACH_SLIDE, MARIO_ANIM_SLIDE_DIVE, AIR_STEP_CHECK_LEDGE_GRAB)

	if m.vel.y < if_then_else(m.actionArg == 2, -100.0, -30.0) then m.vel.y = if_then_else(m.actionArg == 2, -100, -30) end

	m.marioObj.header.gfx.angle.x = m.vel.y * -100

    set_camera_mode(m.area.camera, CAMERA_MODE_FREE_ROAM, 1)
end
ACT_GLIDING = allocate_mario_action(ACT_FLAG_AIR | 0x1100088C)
glides = 2