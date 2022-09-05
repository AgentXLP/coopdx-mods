-- name: Downing
-- description: Downing\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds an incapacitation system where if you're killed in normal gameplay by fall damage or anything of\nthat nature you can be rescued by other players from death.\nBecause of obvious reasons, this mod only works in multiplayer and replaces bubbles.

gGlobalTimer = 0
gGlobalSyncTable.downing = true

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
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

--- @param m MarioState
function update_fvel(m)
    local maxTargetSpeed = 32
    local targetSpeed

    if m.intendedMag < maxTargetSpeed then targetSpeed = m.intendedMag else targetSpeed = maxTargetSpeed end

    if m.forwardVel <= 0 then
        m.forwardVel = m.forwardVel + 1.1
    elseif m.forwardVel <= targetSpeed then
        m.forwardVel = m.forwardVel + 1.1 - m.forwardVel / 43
    elseif m.floor.normal.y >= 0.95 then
        m.forwardVel = m.forwardVel - 1
    end

    if m.forwardVel > 48 then
        m.forwardVel = 48
    end

    m.faceAngle.y = approach_s32(m.faceAngle.y, m.intendedYaw, 0x300, 0x300)
    apply_slope_accel(m)
end

ACT_DOWN = allocate_mario_action(ACT_FLAG_SHORT_HITBOX | ACT_FLAG_STATIONARY)

--- @param m MarioState
function act_down(m)
    if not can_be_downed(m) then gPlayerSyncTable[m.playerIndex].down = false end
    if gPlayerSyncTable[m.playerIndex].downHealth > 0 then m.health = 0x180 else
        gPlayerSyncTable[m.playerIndex].downHealth = 0
        m.health = 0xff
        gPlayerSyncTable[m.playerIndex].down = false
    end

    set_mario_animation(m, MARIO_ANIM_DYING_ON_BACK)
    if m.marioObj.header.gfx.animInfo.animFrame > 35 then m.marioObj.header.gfx.animInfo.animFrame = 35 end
    update_fvel(m)
    m.vel.x = m.vel.x * 0.01
    m.vel.z = m.vel.z * 0.01
    perform_ground_step(m)
    m.pos.y = m.floorHeight

    if gGlobalTimer % 30 == 0 then gPlayerSyncTable[0].downHealth = gPlayerSyncTable[0].downHealth - 1 end
end

--- @param m MarioState
function can_be_downed(m)
    return gGlobalSyncTable.downing and m.numLives > 0
    and m.health < 0x180
    and m.health > 0xff
    and m.prevAction ~= ACT_BUBBLED
    and m.action ~= ACT_BUBBLED
    and (m.prevAction & ACT_GROUP_MASK) ~= ACT_GROUP_CUTSCENE
    and (m.prevAction & ACT_FLAG_INTANGIBLE) == 0
    and (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_CUTSCENE
    and (m.action & ACT_FLAG_INTANGIBLE) == 0
    and m.floor.type ~= SURFACE_BURNING
    and m.floor.type ~= SURFACE_QUICKSAND
    and m.floor.type ~= SURFACE_DEEP_QUICKSAND
    and m.floor.type ~= SURFACE_MOVING_QUICKSAND
    and m.floor.type ~= SURFACE_INSTANT_QUICKSAND
    and m.floor.type ~= SURFACE_SHALLOW_QUICKSAND
    and m.floor.type ~= SURFACE_DEEP_MOVING_QUICKSAND
    and m.floor.type ~= SURFACE_INSTANT_MOVING_QUICKSAND
    and m.floor.type ~= SURFACE_SHALLOW_MOVING_QUICKSAND
    and m.floor.type ~= SURFACE_DEATH_PLANE
    and m.floor.type ~= SURFACE_VERTICAL_WIND
end

--- @param m MarioState
function down(m)
    set_mario_action(m, ACT_DOWN, 0)
    play_character_sound(m, CHAR_SOUND_WAAAOOOW)
end

--- @param m MarioState
function undown(m)
    m.health = 0x380
    set_mario_action(m, ACT_STOP_CROUCHING, 0)
    m.invincTimer = 80
    gPlayerSyncTable[m.playerIndex].downHealth = DOWN_MAX_HEALTH
end

function update()
    gGlobalTimer = gGlobalTimer + 1
    if not network_is_server() then return end
    if network_player_connected_count() < 2 then gGlobalSyncTable.downing = false else gGlobalSyncTable.downing = true end
end

--- @param m MarioState
function mario_update(m)
    if m.playerIndex ~= 0 then return end

    local yoshi = obj_get_first_with_behavior_id(id_bhvYoshi)
    if yoshi ~= nil then obj_mark_for_deletion(yoshi) end

    m.numLives = clamp(m.numLives, 0, 3)

    if can_be_downed(m) then down(m) end

    if m.action == ACT_DOWN then network_player_set_description(gNetworkPlayers[0], "Down", 255, 0, 0, 255) else network_player_set_description(gNetworkPlayers[0], "", 255, 255, 255, 255) end
end

function lerp(a,b,t) return a * (1-t) + b * t end

reviveTime = 210
reviveTimer = reviveTime
soundPlayed = false
function on_hud_render()
    local m = gMarioStates[0]

    local near = nearest_mario_state_to_object(m.marioObj)
    if near ~= nil and dist_between_objects(m.marioObj, near.marioObj) < 200 and near.action == ACT_DOWN and m.action ~= ACT_DOWN then
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_MENU)

        if not soundPlayed then
            play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
            soundPlayed = true
        end
        local text = "[Z ] Revive"
        local out = { x = 0, y = 0, z = 0 }
        djui_hud_world_pos_to_screen_pos(near.pos, out)
        djui_hud_set_color(255, 255, lerp(255, 0, reviveTimer / reviveTime), 255)
        djui_hud_print_text(text, out.x - 250, out.y, 1)
        djui_hud_print_text(tostring(math.floor(reviveTimer / 30)), out.x - 250, out.y + 50, 1)
        if (m.controller.buttonDown & Z_TRIG) ~= 0 then
            if reviveTimer > 0 then reviveTimer = reviveTimer - 1
            else
                reviveTimer = reviveTime
                network_send(true, { global = network_global_index_from_local(near.playerIndex) })
            end
        else reviveTimer = reviveTime end
    else
        soundPlayed = false
        if m.action == ACT_DOWN or m.prevAction == ACT_DOWN then
            djui_hud_set_resolution(RESOLUTION_N64)
            djui_hud_set_font(FONT_HUD)
            djui_hud_set_color(255, 255, 255, 255)
            djui_hud_print_text(tostring(math.floor(gPlayerSyncTable[0].downHealth)), djui_hud_get_screen_width() * 0.53, 35, 1)

            djui_hud_set_color(0, 0, 0, lerp(255, 0, gPlayerSyncTable[0].downHealth / DOWN_MAX_HEALTH))
            djui_hud_render_rect(0, 0, djui_hud_get_screen_width() + 2, djui_hud_get_screen_height() + 2)
        end
    end
end

--- @param m MarioState
function on_set_mario_action(m)
    if m.playerIndex ~= 0 then return end

    if m.prevAction == ACT_DOWN and m.action == ACT_DOWN and can_be_downed(m) then
        gPlayerSyncTable[m.playerIndex].downHealth = gPlayerSyncTable[m.playerIndex].downHealth - 1
        m.invincTimer = 30
    end
end

DOWN_MAX_HEALTH = 70
--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].downHealth = DOWN_MAX_HEALTH
end

function on_packet_receive(table)
    local m = gMarioStates[0]

    if network_global_index_from_local(m.playerIndex) == table.global then
        undown(m)
        if m.numLives - 1 >= 0 then m.numLives = m.numLives - 1 end
        play_character_sound(m, CHAR_SOUND_OKEY_DOKEY)
    end
end

function on_warp()
    gPlayerSyncTable[0].downHealth = DOWN_MAX_HEALTH
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)
hook_event(HOOK_ON_WARP, on_warp)

hook_mario_action(ACT_DOWN, act_down, INTERACT_BOUNCE_TOP)

gServerSettings.bubbleDeath = 0