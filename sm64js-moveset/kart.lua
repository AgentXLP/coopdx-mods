--- @param m MarioState
--- @param angle Vec3f
function kart_angle_smoothing(m, speed, angle)
    angle.y = m.marioObj.header.gfx.angle.y
    local targetAngle0 = -find_floor_slope(m, 0x0)
    local targetAngle2 = find_floor_slope(m, 0x4000)
    local kartAngleMultiplier0 = 0.65
    local kartAngleMultiplier2 = 0.8
    if angle.x < targetAngle0 then
        angle.x = angle.x + speed * kartAngleMultiplier0
        if angle.x > targetAngle0 then
            angle.x = targetAngle0
        end
    else
        angle.x = angle.x - speed * kartAngleMultiplier0
        if angle.x < targetAngle0 then
            angle.x = targetAngle0
        end
    end
    if angle.z < targetAngle2 then
        angle.z = angle.z + speed * kartAngleMultiplier2
        if angle.z > targetAngle2 then
            angle.z = targetAngle2
        end
    else
        angle.z = angle.z - speed * kartAngleMultiplier2
        if angle.z < targetAngle2 then
            angle.z = targetAngle2
        end
    end
    vec3f_copy(angle, m.marioObj.header.gfx.angle)
end

--- @param m MarioState
function act_karting(m)
    local ANGLE_BUF = { x = m.marioObj.header.gfx.angle.x, y = m.marioObj.header.gfx.angle.y, z = m.marioObj.header.gfx.angle.z }
    set_mario_animation(m, MARIO_ANIM_SLIDING_ON_BOTTOM_WITH_LIGHT_OBJ)
    m.marioBodyState.torsoAngle.x = 0x1000
    m.marioBodyState.torsoAngle.z = 0x0000
	local vel = m.forwardVel
	if m.forwardVel > 16 then
		m.particleFlags = m.particleFlags | PARTICLE_DUST
    end
	if (m.input & INPUT_OFF_FLOOR) == 0 then
		-- m.actionState = 0
		if (m.input & INPUT_A_DOWN) ~= 0 and should_begin_sliding(m) == 0 then
			vel = vel + 1.3 * if_then_else((m.input & INPUT_Z_DOWN) ~= 0, -1, 1)
        else
			vel = vel * 0.95545
		end
	end
	if vel < -35 then vel = -35 end
	if vel > 70 then vel = 70 end
    if (m.input & INPUT_B_PRESSED) ~= 0 and (m.input & INPUT_OFF_FLOOR) == 0 and m.actionState == 0 and m.vel.y <= 0.0 then
		m.input = m.input & INPUT_OFF_FLOOR -- Prevent crash / infinite loop.
		m.actionState = 1
		m.pos.y = m.pos.y + 12
		m.vel.y = 32
    end
    if (m.controller.buttonPressed & CUSTOM_BUTTON) ~= 0 and (m.input & INPUT_OFF_FLOOR) == 0 and math.abs(m.forwardVel) < 16 and kartGliderCooldown == 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end
    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 and m.actionState == 0 then
		local number16 = m.intendedYaw - m.faceAngle.y
		local change = math.ceil(10 + (vel*10))
		number16 = if_then_else(number16 > 32767, number16 - 65536, number16)
		number16 = if_then_else(number16 < -32768, number16 + 65536, number16)
		m.faceAngle.y = m.intendedYaw - approach_number(number16, 0, change, change)
    end
	m.forwardVel = vel
	if (m.input & INPUT_OFF_FLOOR) ~= 0 or m.actionState == 1 then
		switch(perform_air_step(m, 1), {
            [AIR_STEP_LANDED] = function()
                if m.vel.y < -32 and (m.input & INPUT_OFF_FLOOR) == 0 and (m.input & INPUT_ABOVE_SLIDE) == 0 then
                    m.vel.y = m.vel.y * -0.25
                else
                    m.actionState = 0
                end
            end,
            [AIR_STEP_HIT_WALL] = function()
                m.forwardVel = m.forwardVel * -0.2
                mario_set_forward_vel(m, 1.25 * m.forwardVel)
            end
        })
		m.marioObj.header.gfx.angle.z = 0
		m.marioObj.header.gfx.angle.x = m.vel.y * -50
	else
		switch (perform_ground_step(m), {
			[GROUND_STEP_LEFT_GROUND] = function()
				if (m.input & INPUT_ABOVE_SLIDE) == 0 then m.pos.y = m.pos.y + 12 end
				m.actionState = 1
            end,
			[GROUND_STEP_HIT_WALL] = function()
				m.forwardVel = m.forwardVel * 0.75
            end
		})
		if (m.actionState == 0) then
			apply_slope_accel(m)
			kart_angle_smoothing(m, 0x800, ANGLE_BUF)
        end
	end
	if (should_begin_sliding(m) ~= 0 and (m.input & INPUT_OFF_FLOOR) == 0) then
		update_sliding(m, 0)
		m.actionState = 0
    end
	m.marioObj.header.gfx.pos.y = m.marioObj.header.gfx.pos.y + if_then_else(m.actionState == 1, 12, 24)
end

ACT_KARTING = allocate_mario_action(ACT_FLAG_ATTACKING | 0x10840452)