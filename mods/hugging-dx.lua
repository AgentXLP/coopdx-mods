-- name: Hugging DX
-- description: Hugging DX v1.0.1\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds hugging other players. It's fundamentally very simple but this is a remake of an old mod I made in 2022 but *better* now. You just go up to someone and a text prompt will show up instructing you to press Y to hug. Hugging someone will also heal you and them. I made this as a commission for my friend occam.

-- localize functions to improve performance
local djui_hud_get_color,djui_hud_set_color,djui_hud_print_text,mario_drop_held_object,mario_push_off_steep_floor,set_mario_action,set_character_animation,play_sound,stationary_ground_step,nearest_mario_state_to_object,dist_between_objects,sins,coss,network_local_index_from_global,djui_hud_set_resolution,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,djui_hud_get_fov_coeff,djui_hud_measure_text,error = djui_hud_get_color,djui_hud_set_color,djui_hud_print_text,mario_drop_held_object,mario_push_off_steep_floor,set_mario_action,set_character_animation,play_sound,stationary_ground_step,nearest_mario_state_to_object,dist_between_objects,sins,coss,network_local_index_from_global,djui_hud_set_resolution,djui_hud_set_font,djui_hud_world_pos_to_screen_pos,djui_hud_get_fov_coeff,djui_hud_measure_text,error

ACT_HUGGING = allocate_mario_action(ACT_GROUP_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE | ACT_FLAG_PAUSE_EXIT)

local easterEgg = false

--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param outlineBrightness number
local function djui_hud_print_outlined_text(message, x, y, scale, outlineBrightness)
    local color = djui_hud_get_color()
    djui_hud_set_color(color.r * outlineBrightness, color.g * outlineBrightness, color.b * outlineBrightness, color.a)
    djui_hud_print_text(message, x - 1, y, scale)
    djui_hud_print_text(message, x + 1, y, scale)
    djui_hud_print_text(message, x, y - 1, scale)
    djui_hud_print_text(message, x, y + 1, scale)
    djui_hud_set_color(color.r, color.g, color.b, color.a)
    djui_hud_print_text(message, x, y, scale)
end

--- @param m MarioState
local function check_common_idle_cancels_hug(m)
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
local function act_hugging(m)
    set_character_animation(m, CHAR_ANIM_IDLE_WITH_LIGHT_OBJ)

    local target = gMarioStates[m.actionArg]

    local cancel = check_common_idle_cancels_hug(m)
    if cancel ~= 0 then return cancel end

    if target.action ~= ACT_HUGGING and m.actionTimer > 15 then
        return set_mario_action(m, ACT_IDLE, 0)
    elseif (m.input & INPUT_B_PRESSED) ~= 0 and m.playerIndex == 0 and not easterEgg then
        -- making up for my mistakes
        play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        easterEgg = true
    end

    m.actionTimer = m.actionTimer + 1
    m.health = m.health + 3

    stationary_ground_step(m)

    return 0
end

--- @param m MarioState
local function player_can_hug(m)
    return (m.action & ACT_FLAG_IDLE) ~= 0 and m.pos.y == m.floorHeight
end

local function update()
    if not huggingApi.enabled then return end

    --- @type MarioState
    local m = gMarioStates[0]
    local nearest = nearest_mario_state_to_object(m.marioObj)
    if nearest == nil then return end

    if player_can_hug(m) and player_can_hug(nearest) and dist_between_objects(m.marioObj, nearest.marioObj) < 300 and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        network_send_to(nearest.playerIndex, true, { globalIndex = gNetworkPlayers[0].globalIndex })
        m.faceAngle.y = nearest.faceAngle.y + 0x8000
        m.pos.x = nearest.pos.x + sins(nearest.faceAngle.y) * 30 + sins(nearest.faceAngle.y + 0x4000) * 10
        m.pos.y = nearest.pos.y
        m.pos.z = nearest.pos.z + coss(nearest.faceAngle.y) * 30 + coss(nearest.faceAngle.y + 0x4000) * 10
        set_mario_action(m, ACT_HUGGING, nearest.playerIndex)
        play_sound(SOUND_MENU_STAR_SOUND, gGlobalSoundSource)
    end
end

--- @param dataTable table
local function on_packet_receive(dataTable)
    set_mario_action(gMarioStates[0], ACT_HUGGING, network_local_index_from_global(dataTable.globalIndex))
    play_sound(SOUND_MENU_STAR_SOUND, gGlobalSoundSource)
end

local function on_hud_render_behind()
    if not huggingApi.enabled then return end

    --- @type MarioState
    local m = gMarioStates[0]
    local nearest = nearest_mario_state_to_object(gMarioStates[0].marioObj)
    if nearest == nil then return end

    if not (player_can_hug(m) and player_can_hug(nearest) and dist_between_objects(m.marioObj, nearest.marioObj) < 300) then
        return
    end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_SPECIAL)

    local pos = { x = nearest.pos.x, y = nearest.pos.y + 250, z = nearest.pos.z }
    local out = gVec3fZero()
    if not djui_hud_world_pos_to_screen_pos(pos, out) then return end

    local scale = -300 / out.z * djui_hud_get_fov_coeff()
    local measure = djui_hud_measure_text("[Y] Hug") * scale * 0.5

    djui_hud_set_color(255, 200, 255, 255)
    djui_hud_print_outlined_text("[Y] Hug", out.x - measure, out.y, scale, 0.5)
end

local sReadonlyMetatable = {
    __index = function(table, key)
        return rawget(table, key)
    end,

    __newindex = function()
        error("Attempt to update a read-only table", 2)
    end
}

_G.huggingApi = {
    enabled = true
}
setmetatable(_G.huggingApi, sReadonlyMetatable)

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)
hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)

hook_mario_action(ACT_HUGGING, act_hugging)