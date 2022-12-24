-- name: Hugging
-- description: Hugging\nBy \\#ec7731\\Agent X\\#dddddd\\\n\nThis mod adds hugging to sm64ex-coop, to hug someone walk up to them and press Y. If the person you're hugging is your beloved, you can press A to kiss them, kissing slowly regenerates health.

KISS_HEALTH_GAIN = 3

acceptedHugActions = {
    [ACT_IDLE] = true,
    [ACT_WALKING] = true,
    [ACT_BRAKING] = true,
    [ACT_BRAKING_STOP] = true,
    [ACT_DECELERATING] = true,
    [ACT_PANTING] = true
}

hint = true

for k, v in pairs(gActiveMods) do
    local name = v.name:lower()
    if v.enabled and name:find("nametags") then
        hint = false
    end
end

function DEGREES(x) return x * 0x10000 / 360 end

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function mario_from_global_index(globalIndex)
    return gMarioStates[network_local_index_from_global(globalIndex)]
end

--- @param m MarioState
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return 1
    end
    if not np.connected then
        return 0
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return 0
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return 0
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return 0
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return 0
    end
    return is_player_active(m)
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

function djui_hud_print_outlined_text(text, x, y, scale, r, g, b, outlineDarkness)
    -- render outline
    djui_hud_set_adjusted_color(r * outlineDarkness, g * outlineDarkness, b * outlineDarkness, 255)
    djui_hud_print_text(text, x - (1*(scale*2)), y, scale)
    djui_hud_print_text(text, x + (1*(scale*2)), y, scale)
    djui_hud_print_text(text, x, y - (1*(scale*2)), scale)
    djui_hud_print_text(text, x, y + (1*(scale*2)), scale)
    -- render text
    djui_hud_set_adjusted_color(r, g, b, 255)
    djui_hud_print_text(text, x, y, scale)
    djui_hud_set_color(255, 255, 255, 255)
end

--- @param o Object
function bhv_heart_particle_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj_scale(o, 0.7)
    obj_set_billboard(o)
end

--- @param o Object
function bhv_heart_particle_loop(o)
    if o.oTimer < 30 then
        o.oPosY = o.oPosY + 10
    else
        obj_mark_for_deletion(o)
    end
end

id_bhvHeartParticle = hook_behavior(nil, OBJ_LIST_UNIMPORTANT, true, bhv_heart_particle_init, bhv_heart_particle_loop)

--- @param m MarioState
function check_common_idle_cancels_hug(m)
    mario_drop_held_object(m)
    if m.floor.normal.y < 0.29237169 then
        return mario_push_off_steep_floor(m, ACT_FREEFALL, 0)
    end

    if (m.input & INPUT_UNKNOWN_10) ~= 0 then
        return set_mario_action(m, ACT_SHOCKWAVE_BOUNCE, 0)
    end

    if (m.input & INPUT_OFF_FLOOR) ~= 0 then
        return set_mario_action(m, ACT_FREEFALL, 0)
    end

    if (m.input & INPUT_ABOVE_SLIDE) ~= 0 then
        return set_mario_action(m, ACT_BEGIN_SLIDING, 0)
    end

    if (m.input & INPUT_FIRST_PERSON) ~= 0 then
        return set_mario_action(m, ACT_FIRST_PERSON, 0)
    end

    if (m.input & INPUT_NONZERO_ANALOG) ~= 0 then
        m.faceAngle.y = m.intendedYaw
        return set_mario_action(m, ACT_WALKING, 0)
    end

    if (m.input & INPUT_Z_DOWN) ~= 0 then
        return set_mario_action(m, ACT_START_CROUCHING, 0)
    end

    return 0
end

--- @param m MarioState
function act_hugging(m)
    set_mario_animation(m, MARIO_ANIM_IDLE_WITH_LIGHT_OBJ)

    local m2 = nearest_mario_state_to_object(m.marioObj)
    if active_player(m2) == 0 or (m.actionTimer > 5 and m2.action ~= ACT_HUGGING) then -- failsafe
        return set_mario_action(m, ACT_IDLE, 0)
    end
    switch(m.actionState, {
        [0] = function()
            m.marioObj.header.gfx.animInfo.animFrame = 10
            m.actionArg = 0
            if (m.input & INPUT_A_PRESSED) ~= 0 or (m2.action == ACT_HUGGING and m2.actionState == 1) then
                m.actionState = 1
            end
        end,
        [1] = function()
            if (m.input & INPUT_A_PRESSED) ~= 0 then m.actionArg = 1 end

            m.pos.x = m2.pos.x + sins(m2.faceAngle.y) * 40
            m.pos.y = m2.pos.y
            m.pos.z = m2.pos.z + coss(m2.faceAngle.y) * 40

            m.marioObj.header.gfx.pos.x = m.marioObj.header.gfx.pos.x + sins(m.faceAngle.y) * 20
            m.marioObj.header.gfx.pos.z = m.marioObj.header.gfx.pos.z + coss(m.faceAngle.y) * 20

            m.marioObj.header.gfx.animInfo.animFrame = 0
            m.marioBodyState.eyeState = MARIO_EYES_CLOSED
            m.health = m.health + KISS_HEALTH_GAIN
            if m.actionArg == 0 then
                play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
                m.actionArg = 1
            elseif m.actionArg == 1 then
                for i = 0, 8 do
                    spawn_non_sync_object(
                        id_bhvHeartParticle,
                        E_MODEL_HEART,
                        m.pos.x + math.random(-100, 100), m.pos.y + 120, m.pos.z + math.random(-100, 100),
                        nil
                    )
                end
                m.actionArg = 2
            end
        end
    })

    m.actionTimer = m.actionTimer + 1

    mario_set_forward_vel(m, 0)
    if check_common_idle_cancels_hug(m) ~= 0 then
        network_send(true, { to = gNetworkPlayers[m2.playerIndex].globalIndex, hug = false })
    end
    stationary_ground_step(m)
end

ACT_HUGGING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_IDLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_INTANGIBLE | ACT_FLAG_STATIONARY)

function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local m = gMarioStates[0]
    local m2 = nearest_mario_state_to_object(m.marioObj)
    if m2 ~= nil and active_player(m2) ~= 0 and dist_between_objects(m.marioObj, m2.marioObj) < 200 then
        if (acceptedHugActions[m.action] and acceptedHugActions[m2.action]) or (m.action == ACT_HUGGING and m2.action == ACT_HUGGING) then
            if hint and (m.action & ACT_GROUP_MASK) == (m2.action & ACT_GROUP_MASK) then
                local scale = 0.35
                local out = { x = 0, y = 0, z = 0 }
                local pos = { x = m2.marioObj.header.gfx.pos.x, y = m2.pos.y + 220, z = m2.marioObj.header.gfx.pos.z }
                djui_hud_world_pos_to_screen_pos(pos, out)

                local text = if_then_else(m.action == ACT_HUGGING, "Press A to kiss", "Press Y to hug")
                local measure = djui_hud_measure_text(text) * scale * 0.5
                if not (m.action == ACT_HUGGING and m.actionState == 1) then djui_hud_print_outlined_text(text, out.x - measure, out.y, scale, 200, 162, 200, 0.5) end
            end

            if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and (m.action ~= ACT_HUGGING or m2.action ~= ACT_HUGGING) then
                m.faceAngle.y = m2.faceAngle.y + 0x8000
                m.pos.x = m2.pos.x + sins(m2.faceAngle.y) * 40
                m.pos.y = m2.pos.y
                m.pos.z = m2.pos.z + coss(m2.faceAngle.y) * 40
                set_mario_action(m, ACT_HUGGING, 0)
                network_send(true, { to = gNetworkPlayers[m2.playerIndex].globalIndex, hug = true })
            end
        end
    end
end

function on_packet_receive(dataTable)
    if gNetworkPlayers[0].globalIndex ~= dataTable.to then return end

    local m = gMarioStates[0]
    if dataTable.hug then
        set_mario_action(m, ACT_HUGGING, 0)
    else
        set_mario_action(m, ACT_IDLE, 0)
    end
end


function on_hug_hint_command()
    hint = not hint
    djui_chat_message_create("Hug hint toggled " .. on_or_off(hint))
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)

hook_mario_action(ACT_HUGGING, act_hugging, INTERACT_PLAYER)

hook_chat_command("hug-hint", "to toggle the a hint over the nearest player's head", on_hug_hint_command)