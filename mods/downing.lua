-- name: Downing
-- description: Downing\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds an incapacitation system where if you're killed in normal gameplay by fall damage or anything of\nthat nature you can be rescued by other players from death.\nBecause of obvious reasons, this mod only works in multiplayer and replaces bubbles.

_G.downHealth = {}
for i = 0, (MAX_PLAYERS - 1) do
    downHealth[i] = 300
end
gGlobalSyncTable.downing = true
gGlobalSyncTable.customFallDamage = false

DOWNING_MIN_PLAYERS = 2

function check_for_mod(name, find)
    local has = false
    for i in pairs(gActiveMods) do
        if find then
            if gActiveMods[i].enabled and gActiveMods[i].name:find(name) then has = true end
        else
            if gActiveMods[i].enabled and gActiveMods[i].name == name then has = true end
        end
    end
    return has
end

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function lerp(a,b,t) return a * (1-t) + b * t end

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

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

l4dHud = check_for_mod("Left 4 Dead 2 HUD", false)

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

--- @param m MarioState
function undown(m)
    m.health = 0x380
    set_mario_action(m, ACT_STOP_CROUCHING, 0)
    m.invincTimer = 60
    gPlayerSyncTable[m.playerIndex].downHealth = 300
    play_character_sound(m, CHAR_SOUND_OKEY_DOKEY)
end

--- @param m MarioState
function act_down(m)
    if network_player_connected_count() < DOWNING_MIN_PLAYERS then undown(m) end

    m.actionTimer = m.actionTimer + 1

    set_mario_animation(m, MARIO_ANIM_DYING_ON_BACK)
    if m.marioObj.header.gfx.animInfo.animFrame > 35 then m.marioObj.header.gfx.animInfo.animFrame = 35 end
    update_fvel(m)
    m.vel.x = m.vel.x * 0.01
    m.vel.z = m.vel.z * 0.01
    perform_ground_step(m)
    m.pos.y = m.floorHeight

    if m.playerIndex == 0 then
        if gPlayerSyncTable[0].downHealth > 0 then
            m.health = 0x180
        else
            gPlayerSyncTable[0].downHealth = 0
            m.health = 0xff
        end

        if m.actionTimer % 30 == 0 then gPlayerSyncTable[0].downHealth = gPlayerSyncTable[0].downHealth - 1 end
        if m.hurtCounter > 0 then
            gPlayerSyncTable[0].downHealth = gPlayerSyncTable[0].downHealth - m.hurtCounter * 4
            m.hurtCounter = 0
            m.invincTimer = 60
        end
    end
end
_G.ACT_DOWN = allocate_mario_action(ACT_FLAG_SHORT_HITBOX | ACT_FLAG_STATIONARY)

--- @param m MarioState
function should_be_downed(m)
    return m.health < 0x180
    and m.health > 0xff
    and (m.action & ACT_GROUP_MASK) ~= ACT_GROUP_CUTSCENE
    and m.action ~= ACT_SPECIAL_DEATH_EXIT
    and m.action ~= ACT_FALLING_DEATH_EXIT
    and m.action ~= ACT_DEATH_EXIT
    and m.action ~= ACT_DEATH_EXIT_LAND
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

function get_fall_damage_multiplier(vel)
    if vel >= 90 and vel < 100 then return 5
    elseif vel >= 100 and vel < 115 then return 10
    elseif vel >= 115 and vel < 130 then return 15
    elseif vel >= 130 then return 20 end

    return 20
end

extraVel = 0
--- @param m MarioState
function mario_update(m)
    _G.downHealth[m.playerIndex] = gPlayerSyncTable[m.playerIndex].downHealth

    if m.playerIndex ~= 0 or network_player_connected_count() < DOWNING_MIN_PLAYERS then return end

    if should_be_downed(m) then
        m.action = _G.ACT_DOWN
        if m.action ~= _G.ACT_DOWN then play_character_sound(m, CHAR_SOUND_WAAAOOOW) end
    end

    if m.action == _G.ACT_DOWN then network_player_set_description(gNetworkPlayers[0], "Down", 255, 0, 0, 255) else network_player_set_description(gNetworkPlayers[0], "", 255, 255, 255, 255) end

    if gGlobalSyncTable.customFallDamage then
        m.peakHeight = m.pos.y

        if m.vel.y <= -75 then
            extraVel = extraVel + 2.5
            m.vel.y = m.vel.y - extraVel
        end

        if (m.prevAction & ACT_FLAG_AIR) ~= 0 and m.prevAction ~= ACT_TWIRLING and m.prevAction ~= ACT_SHOT_FROM_CANNON and (m.action & ACT_FLAG_AIR) == 0 and m.vel.y <= -90 and m.floor.type ~= SURFACE_BURNING and m.floor.type ~= SURFACE_INSTANT_QUICKSAND then
            local dmgMult = get_fall_damage_multiplier(math.abs(m.vel.y))
            if dmgMult == 15 then
                m.health = 383
            else
                local dmg = (m.vel.y * dmgMult)
                m.health = m.health + dmg
                m.health = clamp(m.health, 0xff, 0x880)
            end
            set_camera_shake_from_hit(SHAKE_FALL_DAMAGE)
            m.squishTimer = 30
            play_character_sound(m, CHAR_SOUND_ATTACKED)
        end

        if (m.action & ACT_FLAG_AIR) == 0 then extraVel = 0 end
    end
end

--- @param m MarioState
function on_set_mario_action(m)
    if m.playerIndex ~= 0 or network_player_connected_count() < DOWNING_MIN_PLAYERS then return end

    if (m.prevAction == _G.ACT_DOWN or should_be_downed(m)) and (m.action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED then
        m.health = 0xff
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].downHealth = 300
end

reviveTime = 210
reviveTimer = reviveTime
soundPlayed = false
function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(FONT_MENU)

    local m = gMarioStates[0]

    local near = nearest_mario_state_to_object(m.marioObj)
    if near ~= nil and dist_between_objects(m.marioObj, near.marioObj) < 250 and near.action == _G.ACT_DOWN and m.action ~= _G.ACT_DOWN then

        if not soundPlayed then
            play_sound(SOUND_MENU_CHANGE_SELECT, m.marioObj.header.gfx.cameraToObject)
            soundPlayed = true
        end
        local text = "[Z ] Revive"
        local out = { x = 0, y = 0, z = 0 }
        djui_hud_world_pos_to_screen_pos(near.pos, out)
        djui_hud_set_adjusted_color(255, 255, 0, 255)
        djui_hud_print_text(text, out.x - (djui_hud_measure_text(text) * 0.5), out.y, 1)
        djui_hud_print_text(tostring(math.floor(reviveTimer / 30)), out.x, out.y + 50, 1)
        if (m.controller.buttonDown & Z_TRIG) ~= 0 then
            if reviveTimer > 0 then reviveTimer = reviveTimer - 1
            else
                reviveTimer = reviveTime
                network_send(true, { global = network_global_index_from_local(near.playerIndex) })
            end
        else reviveTimer = reviveTime end
    else
        soundPlayed = false
        if m.action == _G.ACT_DOWN then
            djui_hud_set_resolution(RESOLUTION_N64)
            if not l4dHud then
                djui_hud_set_font(FONT_HUD)
                djui_hud_set_adjusted_color(255, 255, 255, 255)
                djui_hud_print_text(tostring(math.floor(gPlayerSyncTable[0].downHealth)), djui_hud_get_screen_width() * 0.53, 35, 1)
            end
        end
    end

    if gPlayerSyncTable[0].downHealth ~= nil and gPlayerSyncTable[0].downHealth < 300 then
        djui_hud_set_color(0, 0, 0, lerp(255, 0, gPlayerSyncTable[0].downHealth / 300))
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width() + 2, djui_hud_get_screen_height() + 2)
    end
end

function on_packet_receive(table)
    local m = gMarioStates[0]

    if network_global_index_from_local(m.playerIndex) == table.global then undown(m) end
end

function on_warp()
    gPlayerSyncTable[0].downHealth = 300
end

function on_custom_fall_damage_command(msg)
    if msg == "on" then
        gGlobalSyncTable.customFallDamage = true
        djui_chat_message_create("Custom fall damage status: \\#00ff00\\ON")
    else
        gGlobalSyncTable.customFallDamage = false
        djui_chat_message_create("Custom fall damage status: \\#FF0000\\OFF")

    end
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)
hook_event(HOOK_ON_WARP, on_warp)

hook_mario_action(_G.ACT_DOWN, act_down, INTERACT_PLAYER)

if network_is_server() then
    hook_chat_command("custom-fall-damage", "[on|off] to turn Left 4 Dead like fall damage on or off", on_custom_fall_damage_command)
end

gServerSettings.bubbleDeath = 0