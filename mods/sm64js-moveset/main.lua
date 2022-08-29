-- name: sm64js Moveset
-- incompatible: moveset
-- description: sm64js Moveset v1.0.1\n\\#ffffff\\By \\#ff7f00\\Agent X\\#ffffff\\\n\nThis mod adds the sm64js moveset (ground pound jump, dive, ect) into sm64ex-coop.\n\nPress \\#3040ff\\[L]\\#ffffff\\ or \\#3040ff\\[X]\\#ffffff\\ to spawn yourself a kart or glider.

E_MODEL_GLIDER = smlua_model_util_get_id("glider_geo")

_G.switch = function(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function approach_number(current, target, inc, dec)
    if current < target then
        current = current + inc
        if current > target then
            current = target
        end
    else
        current = current - dec
        if current < target then
            current = target
        end
    end
    return current
end

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

CUSTOM_BUTTON = L_TRIG | X_BUTTON

kartGliderCooldown = 0

--- @param m MarioState
function mario_update(m)
    if m.playerIndex ~= 0 then return end

    m.peakHeight = m.pos.y -- disable fall damage

    if m.action == ACT_GROUND_POUND then
        if (m.input & INPUT_B_PRESSED) ~= 0 and m.actionTimer >= 9 then
            m.faceAngle.y = m.intendedYaw
            m.vel.y = 45
            mario_set_forward_vel(m, 30)
            set_mario_action(m, ACT_DIVE, 0)
        end
    elseif m.action == ACT_GROUND_POUND_LAND then
        if (m.input & INPUT_A_PRESSED) ~= 0 then
            m.vel.y = 50
            mario_set_forward_vel(m, 20)
            set_mario_action(m, ACT_TRIPLE_JUMP, 0)
        end
    elseif m.action == ACT_FORWARD_ROLLOUT then
        if (m.input & INPUT_B_PRESSED) ~= 0 and m.prevAction == ACT_DIVE_SLIDE then
            m.vel.y = 15
            mario_set_forward_vel(m, 30)
            set_mario_action(m, ACT_DIVE, 0)
        end
    elseif m.action == ACT_SHOT_FROM_CANNON then
        if m.vel.y < 0 then
            spawn_non_sync_object(
                id_bhvWingCap,
                E_MODEL_NONE,
                m.pos.x + m.vel.x, m.pos.y + m.vel.y, m.pos.z + m.vel.z,
                nil
            )
            set_mario_action(m, ACT_FLYING, 0)
        end
    end

    if m.prevAction == ACT_GLIDING and m.action ~= ACT_GLIDING and (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_SUBMERGED then set_camera_mode(m.area.camera, m.area.camera.defMode, 1) end

    if kartGliderCooldown > 0 then kartGliderCooldown = kartGliderCooldown - 1 end

    if (m.controller.buttonPressed & CUSTOM_BUTTON) ~= 0 and kartGliderCooldown == 0 and m.health >= 384 then
        if m.action == ACT_JUMP or m.action == ACT_DIVE or m.action == ACT_GROUND_POUND or m.action == ACT_WALL_KICK_AIR
        or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP or m.action == ACT_LONG_JUMP or m.action == ACT_BACKFLIP
        or m.action == ACT_JUMP_KICK or m.action == ACT_SLIDE_KICK or m.action == ACT_WATER_JUMP then
            if glides > 0 then
                if m.action == ACT_WATER_JUMP then m.vel.y = 50 end
                set_mario_action(m, ACT_GLIDING, 0)
                glides = glides - 1
            end
        elseif (m.input & INPUT_OFF_FLOOR) == 0 then
            if math.abs(m.forwardVel) < 16 then set_mario_action(m, ACT_KARTING, 0) end
        end
    end
end

--- @param m MarioState
function on_set_mario_action(m)
    if m.prevAction == ACT_GLIDING or m.prevAction == ACT_KARTING then kartGliderCooldown = 10 end
    if (m.action & ACT_FLAG_AIR) == 0 or m.action == ACT_DIVE then glides = 2 end

    -- stickers
    if m.action == ACT_GLIDING then spawn_sticker(m, E_MODEL_GLIDER, -12, 0.27)
    elseif m.action == ACT_KARTING then spawn_sticker(m, E_MODEL_KOOPA_SHELL, 0, 1)
    elseif m.action ~= ACT_GLIDING and m.playerIndex == 0 and m.action ~= ACT_KARTING then
        despawn_sticker()
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].targetGlider = 0
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

hook_mario_action(ACT_KARTING, act_karting, INTERACT_PLAYER)
hook_mario_action(ACT_GLIDING, act_gliding, INTERACT_PLAYER)