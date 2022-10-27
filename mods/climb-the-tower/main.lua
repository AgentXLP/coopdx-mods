-- name: Climb the Tower
-- incompatible: gamemode
-- description: Climb the Tower v1.3\nBy: \\#ec7731\\Agent X\\#ffffff\\\n\nThis gamemode revolves around getting the fastest time and getting to the top of the tower the fastest, you can view the scores with /scoreboard\nIf you wish to play another gamemode on this map (e.g. manhunt / hide and seek) then run /ctt off on host.

LEVEL_CTT = LEVEL_PSS

gGlobalSyncTable.climbTheTower = true
doubleJumps = 3

function in_range(val, low, max)
    return val >= low and val <= max
end

--- @param m MarioState
function mario_update(m)
    if m.playerIndex ~= 0 or not gGlobalSyncTable.climbTheTower then return end

    m.peakHeight = m.pos.y

    if not gPlayerSyncTable[0].finished then
        gPlayerSyncTable[0].time = gPlayerSyncTable[0].time + 1
    end

    if gNetworkPlayers[0].currLevelNum ~= LEVEL_CTT then
        warp_to_level(LEVEL_CTT, 1, 1)
        gPlayerSyncTable[0].time = 0
        gPlayerSyncTable[0].finished = false
    end

    if m.pos.y >= 10886 and (m.action & ACT_FLAG_AIR) == 0 then
        gPlayerSyncTable[0].finished = true
    end

    if (m.controller.buttonPressed & D_JPAD) ~= 0 then
        on_reset_command()
    end

    -- special double jump
    if (m.action & ACT_GROUP_MASK) == ACT_GROUP_AIRBORNE and (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
        if doubleJumps > 0 then
            doubleJumps = doubleJumps - 1
            set_mario_action(m, ACT_LONG_JUMP, 0)
            m.faceAngle.y = m.intendedYaw
            m.vel.y = 50
        end
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].time = 0
    gPlayerSyncTable[m.playerIndex].prevTime = 0
    gPlayerSyncTable[m.playerIndex].finished = false
end

function on_warp()
    gPlayerSyncTable[0].time = 0
    gPlayerSyncTable[0].finished = false
    doubleJumps = 3
    triggered = false
end

function on_hud_render()
    if not gGlobalSyncTable.climbTheTower then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local text = "0.000 seconds"
    if gPlayerSyncTable[0].time ~= nil then
        text = tostring(string.format("%.3f", gPlayerSyncTable[0].time / 30)) .. " seconds"
    else
        return
    end

    local screenWidth = djui_hud_get_screen_width()
    local width = djui_hud_measure_text(text) * 0.50

    local x = (screenWidth - width) / 2.0
    local y = 0

    djui_hud_set_color(0, 0, 0, 128)
    djui_hud_render_rect(x - 6, y, width + 12, 16)
    if gPlayerSyncTable[0].time < 2700 then
        djui_hud_set_color(0, 255, 0, 255)
    elseif in_range(gPlayerSyncTable[0].time, 2700, 3600) then
        djui_hud_set_color(255, 255, 0, 255)
    else
        djui_hud_set_color(255, 0, 0, 255)
    end
    djui_hud_print_text(text, x, y, 0.50)

    djui_hud_set_color(255, 255, 255, 255)
    hud_render_power_meter(gMarioStates[0].health, djui_hud_get_screen_width() - 62, 0, 64, 64)

    djui_hud_set_font(FONT_HUD)
    djui_hud_print_text(tostring(doubleJumps), 5, 5, 1)
end


function on_ctt_command(msg)
    if msg == "on" then
        gGlobalSyncTable.climbTheTower = true
        djui_chat_message_create("CTT enabled! Based.")
        hud_hide()
    else
        gGlobalSyncTable.climbTheTower = false
        djui_chat_message_create("CTT disabled.")
        hud_show()
    end
    return true
end

function on_reset_command()
    warp_to_level(LEVEL_CTT, 1, 1)
    return true
end

function on_scoreboard_command()

    for i = 0, (MAX_PLAYERS - 1) do
        if gNetworkPlayers[i].connected then
            djui_chat_message_create(gNetworkPlayers[i].name .. "\\#ffffff\\ - " .. tostring(string.format("%.3f", gPlayerSyncTable[i].prevTime / 30)) .. " seconds")
        end
    end
    return true
end

function on_finished_change(tag, oldVal, newVal)
    if not gGlobalSyncTable.climbTheTower then return end

    if newVal then
        play_race_fanfare()
        gPlayerSyncTable[0].prevTime = gPlayerSyncTable[0].time
        djui_chat_message_create("Your time: " .. "\\#ffffff\\" .. tostring(string.format("%.3f", gPlayerSyncTable[0].prevTime / 30)) .. " seconds")
        djui_chat_message_create("Run /reset to go back to the start or press DPad Down.")
    end
end

hud_hide()
smlua_text_utils_secret_star_replace(COURSE_PSS,      "   CLIMB THE TOWER")
smlua_text_utils_dialog_replace(DIALOG_149, 1, 4, 30, 200, "Welcome to Climb the Tower\
This is a showcase of\
sm64ex-coop unst 24's\
new custom level system.\
In the skies above Peach's\
Castle, we came together\
and built a big obstacle\
course for the ones who\
wish to take the\
course and unlock their\
true splendor.")

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_PAUSE_EXIT, function() return false end)

hook_chat_command("reset", "to reset the level for everybody", on_reset_command)
hook_chat_command("scoreboard", "not in any paticular order because sorting stuff is hard", on_scoreboard_command)

if network_is_server() then
    hook_chat_command("ctt", "[on|off] modify whether or not the gamemode is enabled", on_ctt_command)
end

hook_on_sync_table_change(gPlayerSyncTable[0], "finished", 0, on_finished_change)