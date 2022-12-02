-- name: Pong
-- incompatible: gamemode
-- description: Pong\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds pong to sm64ex-coop, the first player that joins the game becomes the opponent and the ones after are spectators, this mod is meant to be played in only 2 players and is practically completely custom meaning you're not even technically playing Super Mario 64.

ROUND_STATE_INACTIVE = 0
ROUND_STATE_ACTIVE = 1
ROUND_COOLDOWN = 150

gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
gGlobalSyncTable.roundCooldown = 1

gGlobalSyncTable.ballPosX = 0
gGlobalSyncTable.ballPosY = 1
gGlobalSyncTable.ballSpeedX = 0
gGlobalSyncTable.ballSpeedY = 0

gGlobalSyncTable.paddlePosY1 = 0
gGlobalSyncTable.paddlePosY2 = 0

ballTexture = 1
gGlobalSyncTable.ballSpeedModifier = 0

ballTextures = {
    gTextures.mario_head,
    gTextures.luigi_head,
    gTextures.toad_head,
    gTextures.waluigi_head,
    gTextures.wario_head
}

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function name_without_hex(name)
    local s = ''
    local inSlash = false
    for i = 1, #name do
        local c = name:sub(i,i)
        if c == '\\' then
            inSlash = not inSlash
        elseif not inSlash then
            s = s .. c
        end
    end
    return s
end

function check_collided_with_paddle(paddleX, paddleY, ballX, ballY)
    if paddleX > ballX + 16 - 1 or   -- is paddle on the right of ball?
       paddleY > ballY + 16 - 1 or   -- is paddle under ball?
       ballX > paddleX + 10 - 1 or   -- is ball on the right side of paddle?
       ballY > paddleY + 60 - 1 then -- is ball under paddle?
        return false
    else
        return true
    end
end

function apply_speed_modifier()
    if gGlobalSyncTable.ballSpeedX < 0 then gGlobalSyncTable.ballSpeedX = gGlobalSyncTable.ballSpeedX - gGlobalSyncTable.ballSpeedModifier
    else gGlobalSyncTable.ballSpeedX = gGlobalSyncTable.ballSpeedX + gGlobalSyncTable.ballSpeedModifier end
    if gGlobalSyncTable.ballSpeedY < 0 then gGlobalSyncTable.ballSpeedY = gGlobalSyncTable.ballSpeedY - gGlobalSyncTable.ballSpeedModifier
    else gGlobalSyncTable.ballSpeedY = gGlobalSyncTable.ballSpeedY + gGlobalSyncTable.ballSpeedModifier end
end

function update()
    if network_player_connected_count() < 2 or not gNetworkPlayers[0].currAreaSyncValid then return end

    if network_is_server() then
        local left = network_local_index_from_global(0)
        local right = network_local_index_from_global(1)

        djui_hud_set_resolution(RESOLUTION_N64)
        local width = djui_hud_get_screen_width()
        local height = djui_hud_get_screen_height()

        if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
            if gGlobalSyncTable.roundCooldown > 0 then
                -- wait
                gGlobalSyncTable.roundCooldown = gGlobalSyncTable.roundCooldown - 1
            else
                -- game init
                gGlobalSyncTable.roundState = ROUND_STATE_ACTIVE
                gGlobalSyncTable.ballSpeedModifier = 0
                gPlayerSyncTable[left].won = false
                gPlayerSyncTable[right].won = false
                ballTexture = math.floor(math.random(1, 5))
                gGlobalSyncTable.ballPosX = width * 0.5
                gGlobalSyncTable.ballPosY = (height * 0.5) - 16
                gGlobalSyncTable.ballSpeedX = math.random(-1, 1)
                gGlobalSyncTable.ballSpeedY = math.random(-1, 1)
                gGlobalSyncTable.paddlePosY1 = (height * 0.5) - 30
                gGlobalSyncTable.paddlePosY2 = (height * 0.5) - 30
            end
        else
            -- move ball
            if gGlobalSyncTable.ballSpeedX == 0 then gGlobalSyncTable.ballSpeedX = -1 end
            if gGlobalSyncTable.ballSpeedY == 0 then gGlobalSyncTable.ballSpeedY = -1 end
            gGlobalSyncTable.ballPosX = gGlobalSyncTable.ballPosX + gGlobalSyncTable.ballSpeedX
            gGlobalSyncTable.ballPosY = gGlobalSyncTable.ballPosY + gGlobalSyncTable.ballSpeedY

            -- prevent ball from going off screen
            if gGlobalSyncTable.ballPosY > height - 16 then
                gGlobalSyncTable.ballPosY = height - 16
                gGlobalSyncTable.ballSpeedY = gGlobalSyncTable.ballSpeedY * -1
            elseif gGlobalSyncTable.ballPosY < 0 then
                gGlobalSyncTable.ballPosY = 0
                gGlobalSyncTable.ballSpeedY = gGlobalSyncTable.ballSpeedY * -1
            end

            -- check paddle collision
            if check_collided_with_paddle(10, gGlobalSyncTable.paddlePosY1, gGlobalSyncTable.ballPosX, gGlobalSyncTable.ballPosY) then
                gGlobalSyncTable.ballPosX = 22
                gGlobalSyncTable.ballSpeedX = gGlobalSyncTable.ballSpeedX * -1
                gGlobalSyncTable.ballSpeedModifier = gGlobalSyncTable.ballSpeedModifier + 0.05
                apply_speed_modifier()
            elseif check_collided_with_paddle(width - 20, gGlobalSyncTable.paddlePosY2, gGlobalSyncTable.ballPosX, gGlobalSyncTable.ballPosY) then
                -- right paddle was hacky to get working for some reason, had to subtract 35
                gGlobalSyncTable.ballPosX = width - 35
                gGlobalSyncTable.ballSpeedX = gGlobalSyncTable.ballSpeedX * -1
                gGlobalSyncTable.ballSpeedModifier = gGlobalSyncTable.ballSpeedModifier + 0.05
                apply_speed_modifier()
            end

            -- check to see if someone has won
            if gGlobalSyncTable.ballPosX > width then
                gPlayerSyncTable[left].won = true
                gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
                gGlobalSyncTable.roundCooldown = ROUND_COOLDOWN
            elseif gGlobalSyncTable.ballPosX < -16 then
                gPlayerSyncTable[right].won = true
                gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
                gGlobalSyncTable.roundCooldown = ROUND_COOLDOWN
            end
        end
    end
end

function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_HUD)

    local width = djui_hud_get_screen_width()
    local height = djui_hud_get_screen_height()
    local centerX = width * 0.5
    local centerY = height * 0.5

    local left = network_local_index_from_global(0)
    local right = network_local_index_from_global(1)

    -- clear
    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_color(0, 0, 0, 255)
    djui_hud_render_rect(-20, -20, djui_hud_get_screen_width() + 20, djui_hud_get_screen_height() + 20)
    djui_hud_set_resolution(RESOLUTION_N64)

    djui_hud_set_color(255, 255, 255, 255)

    -- if there is no opponent or sync is not valid yet
    if network_player_connected_count() < 2 or not gNetworkPlayers[0].currAreaSyncValid then
        djui_hud_set_font(FONT_NORMAL)
        djui_hud_print_text("Waiting for 2nd player...", centerX - (djui_hud_measure_text("Waiting for 2nd player...") * 0.5), centerY - 20, 1)
        gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
        gGlobalSyncTable.roundCooldown = 1
        return
    end

    local m = gMarioStates[0]

    -- if is the host or the first person joined, allow paddle control
    if gNetworkPlayers[0].globalIndex < 2 then
        local pos = "paddlePosY" .. gNetworkPlayers[0].globalIndex + 1
        if (m.controller.buttonDown & U_JPAD) ~= 0 or (m.controller.stickY) > 1 then
            gGlobalSyncTable[pos] = gGlobalSyncTable[pos] - 5
        elseif (m.controller.buttonDown & D_JPAD) ~= 0 or (m.controller.stickY) < -1 then
            gGlobalSyncTable[pos] = gGlobalSyncTable[pos] + 5
        end

        if gGlobalSyncTable[pos] < 0 then gGlobalSyncTable[pos] = 0 end
        if gGlobalSyncTable[pos] > height - 60 then gGlobalSyncTable[pos] = height - 60 end
    end

    -- draw paddles
    djui_hud_render_rect(10, gGlobalSyncTable.paddlePosY1, 10, 60)
    djui_hud_render_rect(width - 20, gGlobalSyncTable.paddlePosY2, 10, 60)

    -- draw ball
    djui_hud_render_texture(ballTextures[ballTexture], gGlobalSyncTable.ballPosX, gGlobalSyncTable.ballPosY, 1, 1)

    -- draw score
    local scoreDisplay = gPlayerSyncTable[left].score .. " / " .. gPlayerSyncTable[right].score
    djui_hud_print_text(scoreDisplay, centerX - (djui_hud_measure_text(scoreDisplay) * 0.5), 10, 1)

    -- if one of the players won, in the event both players win SOMEHOW, the right will be shown as the winner
    if gPlayerSyncTable[left].won or gPlayerSyncTable[right].won then
        djui_hud_set_font(FONT_NORMAL)

        local text = ""
        if gPlayerSyncTable[left].won then
            text = name_without_hex(gNetworkPlayers[left].name) .. " won"
        elseif gPlayerSyncTable[right].won then
            text = name_without_hex(gNetworkPlayers[right].name) .. " won"
        end

        -- draw player won text
        djui_hud_set_color(255, 255, 0, 255)
        djui_hud_print_text(text, centerX - (djui_hud_measure_text(text) * 0.5), centerY - 20, 1)
    end
end

--- @param m MarioState
function mario_update(m)
    -- prevent mario from doing anything
    set_mario_action(m, ACT_UNINITIALIZED, 0)
    camera_freeze()

    if m.playerIndex ~= 0 then return end

    -- remove unnecessary objects that just make noise
    local birds = obj_get_first_with_behavior_id(id_bhvBirdsSoundLoop)
    while birds ~= nil do
        obj_mark_for_deletion(birds)
        birds = obj_get_next_with_same_behavior_id(birds)
    end
    local ambience = obj_get_first_with_behavior_id(id_bhvWaterfallSoundLoop)
    while ambience ~= nil do
        obj_mark_for_deletion(ambience)
        ambience = obj_get_next_with_same_behavior_id(ambience)
    end
    -- sorry yoshi
    local yoshi = obj_get_first_with_behavior_id(id_bhvYoshi)
    if yoshi ~= nil then obj_mark_for_deletion(yoshi) end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].score = 0
end

function on_won_changed(tag, oldVal, newVal)
    -- if you have just won
    if newVal and not oldVal then gPlayerSyncTable[0].score = gPlayerSyncTable[0].score + 1 end
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

hook_on_sync_table_change(gPlayerSyncTable[0], "won", 0, on_won_changed)