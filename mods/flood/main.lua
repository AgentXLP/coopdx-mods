-- name: Flood
-- incompatible: gamemode
-- description: Flood v2.3.2\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds a flood escape gamemode\nto sm64ex-coop, you must escape the flood and reach the top of the level before everything is flooded.\n\nSpecial thanks to Mr.Needlemouse64 and Blocky for their respective easter eggs.

if unsupported then return end

FLOOD_VERSION = "2.3.2"

local ROUND_STATE_INACTIVE = 0
ROUND_STATE_ACTIVE         = 1
local ROUND_COOLDOWN       = 600

local SPEEDRUN_MODE_OFF = 0
local SPEEDRUN_MODE_PROGRESS = 1
local SPEEDRUN_MODE_RESTART = 2

gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
gGlobalSyncTable.timer = ROUND_COOLDOWN
gGlobalSyncTable.level = LEVEL_BOB
gGlobalSyncTable.waterLevel = -20000
gGlobalSyncTable.speedMultiplier = 1

local gGlobalTimer = 0
local listedSurvivors = false
savedStarPoints = 0
savedSpeedMultiplier = 1
local setScore = false
score = if_then_else(cheats, 0, tonumber(mod_storage_load("score")) or 0)
local speedrunner = 0

-- localize functions to improve performance
local math_min = math.min
local math_floor = math.floor
local math_random = math.random
local math_max = math.max
local camera_set_use_course_specific_settings = camera_set_use_course_specific_settings
local djui_chat_message_create = djui_chat_message_create
local djui_hud_get_screen_height = djui_hud_get_screen_height
local djui_hud_get_screen_width = djui_hud_get_screen_width
local djui_hud_measure_text = djui_hud_measure_text
local djui_hud_print_text = djui_hud_print_text
local djui_hud_render_rect = djui_hud_render_rect
local djui_hud_set_font = djui_hud_set_font
local djui_hud_set_resolution = djui_hud_set_resolution
local play_music = play_music
local play_race_fanfare = play_race_fanfare
local play_secondary_music = play_secondary_music
local play_sound = play_sound
local init_single_mario = init_single_mario
local set_mario_action = set_mario_action
local vec3f_copy = vec3f_copy
local vec3f_dist = vec3f_dist
local mod_storage_load = mod_storage_load
local mod_storage_save = mod_storage_save
local network_player_connected_count = network_player_connected_count
local network_player_set_description = network_player_set_description
local network_is_server = network_is_server
local disable_time_stop = disable_time_stop
local obj_scale = obj_scale
local spawn_mist_particles = spawn_mist_particles
local save_file_erase_current_backup_save = save_file_erase_current_backup_save
local save_file_set_flags = save_file_set_flags
local smlua_audio_utils_replace_sequence = smlua_audio_utils_replace_sequence
local warp_to_level = warp_to_level
local clamp = clamp
local clampf = clampf
local max = max
local hud_get_value = hud_get_value
local hud_hide = hud_hide
local hud_render_power_meter = hud_render_power_meter
local save_file_set_using_backup_slot = save_file_set_using_backup_slot
local set_environment_region = set_environment_region
local obj_check_hitbox_overlap = obj_check_hitbox_overlap
local obj_get_first_with_behavior_id = obj_get_first_with_behavior_id
local spawn_non_sync_object = spawn_non_sync_object
local smlua_text_utils_secret_star_replace = smlua_text_utils_secret_star_replace
local find_floor_height = find_floor_height

function speedrun_mode(mode)
    if mode == nil then
        return speedrunner > 0 and network_player_connected_count() == 1
    else
        return speedrunner == mode and network_player_connected_count() == 1
    end
end

-- runs serverside
local function round_start()
    gGlobalSyncTable.roundState = ROUND_STATE_ACTIVE
    gGlobalSyncTable.timer = if_then_else(gGlobalSyncTable.level == LEVEL_BONUS, 730, 100)
end

-- runs serverside
local function round_end()
    gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
    gGlobalSyncTable.timer = ROUND_COOLDOWN
    gGlobalSyncTable.waterLevel = -20000
end

function level_restart()
    round_start()
    init_single_mario(gMarioStates[0])
    mario_set_full_health(gMarioStates[0])
    gLevels[gGlobalSyncTable.level].time = 0
    warp_to_level(gGlobalSyncTable.level, gLevels[gGlobalSyncTable.level].area, if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS, 99, 6))
end

function set_score()
    if setScore then return end

    local m = gMarioStates[0]
    local multiplier = math_min(gGlobalSyncTable.speedMultiplier, savedSpeedMultiplier)
    if moveset then
        multiplier = math_min(1, multiplier)
    end
    local oldScore = score
    local starPoints = math_round(savedStarPoints * multiplier)
    local coinPoints = math_floor(m.numCoins * 0.1 * multiplier)
    local bitsPoints = math_round(40 * multiplier)
    score = score + math_round(gLevels[gGlobalSyncTable.level].points * multiplier)
    if not moveset then
        score = score + starPoints + coinPoints + if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_BITS and m.numCoins >= 75, bitsPoints, 0)
    end
    mod_storage_save("score", tostring(score))
    gPlayerSyncTable[0].score = score
    djui_chat_message_create(string.format(
        "Score: %d -> %d%s%s%s",
        oldScore, -- ->
        gPlayerSyncTable[0].score,
        if_then_else(starPoints ~= 0, " (" .. starPoints .. " bonus star points)", ""),
        if_then_else(coinPoints ~= 0, " (" .. coinPoints .. " bonus coin points)", ""),
        if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_BITS and m.numCoins >= 75, " (" .. bitsPoints .. " bonus points for collecting all coins in BITS)", "")
    ))

    setScore = true
end

local function server_update()
    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level then
            gGlobalSyncTable.waterLevel = gGlobalSyncTable.waterLevel + gLevels[gGlobalSyncTable.level].speed * gGlobalSyncTable.speedMultiplier

            local active = 0
            for i = 0, (MAX_PLAYERS - 1) do
                local m = gMarioStates[i]
                if gNetworkPlayers[i].connected and m.health > 0xff and not gPlayerSyncTable[i].finished then
                    active = active + 1
                end
            end

            if active == 0 then
                local dead = 0
                for i = 0, (MAX_PLAYERS) - 1 do
                    if gNetworkPlayers[i].connected and gMarioStates[i].health <= 0xff then
                        dead = dead + 1
                    end
                end
                if dead == network_player_connected_count() or speedrun_mode() then
                    gGlobalSyncTable.timer = 0
                end

                if gGlobalSyncTable.timer > 0 then
                    gGlobalSyncTable.timer = gGlobalSyncTable.timer - 1
                else
                    round_end()

                    if not speedrun_mode() or speedrun_mode(SPEEDRUN_MODE_PROGRESS) then
                        -- move to the next level
                        local finished = 0
                        for i = 0, (MAX_PLAYERS - 1) do
                            if gNetworkPlayers[i].connected and gPlayerSyncTable[i].finished then
                                finished = finished + 1
                            end
                        end

                        if finished ~= 0 then
                            -- calculate position
                            local position = 1
                            for k, v in pairs(gMapRotation) do
                                if gGlobalSyncTable.level == v then
                                    position = k
                                end
                            end

                            position = position + 1
                            if position > FLOOD_LEVEL_COUNT - FLOOD_BONUS_LEVELS then
                                position = 1
                            end

                            gGlobalSyncTable.level = gMapRotation[position]
                        end
                    end
                end
            end
        end
    else
        if network_player_connected_count() > 1 then
            if gGlobalSyncTable.timer > 0 then
                gGlobalSyncTable.timer = gGlobalSyncTable.timer - 1

                if gGlobalSyncTable.timer == 30 or gGlobalSyncTable.timer == 60 or gGlobalSyncTable.timer == 90 then
                    play_sound(SOUND_MENU_CHANGE_SELECT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                elseif gGlobalSyncTable.timer == 11 then
                    play_sound(SOUND_GENERAL_RACE_GUN_SHOT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
                end
            else
                round_start()
            end
        end
    end
end

local function update()
    if network_is_server() then server_update() end

    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_LOBBY or gNetworkPlayers[0].currActNum ~= 0 then
            if speedrun_mode() then
                level_restart()
            end

            warp_to_level(LEVEL_LOBBY, 1, 0)

            if not listedSurvivors and gGlobalTimer > 5 then
                listedSurvivors = true
                local finished = 0
                djui_chat_message_create("Survivors:")
                for i = 0, (MAX_PLAYERS - 1) do
                    if gNetworkPlayers[i].connected and gPlayerSyncTable[i].finished then
                        djui_chat_message_create(network_get_player_text_color_string(i) .. gNetworkPlayers[i].name)
                        finished = finished + 1
                    end
                end
                if finished == 0 then
                    djui_chat_message_create("\\#ff0000\\None")
                end
            end
        end
    elseif gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        local act = if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS, 99, 6)
        if gNetworkPlayers[0].currLevelNum ~= gGlobalSyncTable.level or gNetworkPlayers[0].currActNum ~= act then
            listedSurvivors = false
            mario_set_full_health(gMarioStates[0])
            gLevels[gGlobalSyncTable.level].time = 0
            gPlayerSyncTable[0].finished = false
            setScore = false
            warp_to_level(gGlobalSyncTable.level, gLevels[gGlobalSyncTable.level].area, act)
        end
    end

    -- stops the star spawn cutscenes from happening
    local m = gMarioStates[0]
    if m.area ~= nil and m.area.camera ~= nil and (m.area.camera.cutscene == CUTSCENE_STAR_SPAWN or m.area.camera.cutscene == CUTSCENE_RED_COIN_STAR_SPAWN) then
        m.area.camera.cutscene = 0
        m.freeze = 0
        disable_time_stop()
    end

    gGlobalTimer = gGlobalTimer + 1
end

--- @param m MarioState
local function mario_update(m)
    if not gNetworkPlayers[m.playerIndex].connected then return end

    if m.health <= 0xff then
        network_player_set_description(gNetworkPlayers[m.playerIndex], tostring(gPlayerSyncTable[m.playerIndex].score), 255, 0, 0, 255)
    else
        network_player_set_description(gNetworkPlayers[m.playerIndex], tostring(gPlayerSyncTable[m.playerIndex].score), 0, 255, 0, 255)
    end

    if m.playerIndex ~= 0 then return end

    if screen then
        mario_set_full_health(m)
        set_mario_action(m, ACT_PAUSE, 0)
        return
    end

    -- action specific modifications
    if m.action == ACT_STEEP_JUMP then
        m.action = ACT_JUMP
    elseif m.action == ACT_JUMBO_STAR_CUTSCENE then
        m.flags = m.flags | MARIO_WING_CAP
    end

    -- disable instant warps
    if m.floor ~= nil and (m.floor.type == SURFACE_WARP or (m.floor.type >= SURFACE_PAINTING_WARP_D3 and m.floor.type <= SURFACE_PAINTING_WARP_FC) or (m.floor.type >= SURFACE_INSTANT_WARP_1B and m.floor.type <= SURFACE_INSTANT_WARP_1E)) then
        m.floor.type = SURFACE_DEFAULT
    end

    -- disable damage in lobby
    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        mario_set_full_health(m)
        m.peakHeight = m.pos.y
        return
    end

    if (gNetworkPlayers[0].currLevelNum == LEVEL_SSL or gNetworkPlayers[0].currLevelNum == LEVEL_BONUS or gNetworkPlayers[0].currLevelNum == LEVEL_HMC) and not _G.ommEnabled then
        romhack_camera(m)
    end

    -- dialog boxes
    if (m.action == ACT_SPAWN_NO_SPIN_AIRBORNE or m.action == ACT_SPAWN_NO_SPIN_LANDING or m.action == ACT_SPAWN_SPIN_AIRBORNE or m.action == ACT_SPAWN_SPIN_LANDING) and m.pos.y < m.floorHeight + 10 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    -- manage CTT
    if gNetworkPlayers[0].currLevelNum == LEVEL_BONUS and game == GAME_VANILLA then
        m.peakHeight = m.pos.y

        local star = obj_get_first_with_behavior_id(id_bhvFinalStar)
        if star ~= nil and obj_check_hitbox_overlap(m.marioObj, star) and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            spawn_mist_particles()
            set_mario_action(m, ACT_JUMBO_STAR_CUTSCENE, 0)
        end

        if m.action == ACT_JUMBO_STAR_CUTSCENE and m.actionTimer >= 499 then
            set_mario_spectator(m)
        end
    end

    -- check if the player has reached the end of the level 
    if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level and not gPlayerSyncTable[0].finished and ((gNetworkPlayers[0].currLevelNum ~= LEVEL_BONUS and m.pos.y == m.floorHeight)
    or (gNetworkPlayers[0].currLevelNum == LEVEL_BONUS and m.action == ACT_JUMBO_STAR_CUTSCENE) or (m.action & ACT_FLAG_ON_POLE) ~= 0)
    and vec3f_dist(m.pos, gLevels[gGlobalSyncTable.level].goalPos) < 600 then
        gPlayerSyncTable[0].finished = true

        if gNetworkPlayers[0].currLevelNum ~= LEVEL_BONUS then
            djui_chat_message_create("\\#00ff00\\You escaped the flood!")
            if gNetworkPlayers[0].currLevelNum ~= LEVEL_BITS then
                play_race_fanfare()
            else
                play_secondary_music(SEQ_EVENT_CUTSCENE_COLLECT_STAR, 10, 110, 10)
            end
        elseif game == GAME_VANILLA then
            djui_chat_message_create("\\#00ff00\\You escaped the \\#ffff00\\final\\#00ff00\\ flood! Congratulations!")
            play_secondary_music(SEQ_EVENT_CUTSCENE_VICTORY, 0, 70, 30)
        end

        djui_chat_message_create("Your time: " .. string.format("%.3f", gLevels[gGlobalSyncTable.level].time / 30))

        if not cheats then
            set_score()
            if gNetworkPlayers[0].currLevelNum == LEVEL_BITS and m.numCoins >= 75 then
                network_send(true, { score = true })
            end
        end
    end

    -- update spectator if finished, manage other things if not
    if gPlayerSyncTable[0].finished then
        mario_set_full_health(m)
        if network_player_connected_count() > 1 and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            set_mario_spectator(m)
        end
    else
        if m.pos.y + 40 < gGlobalSyncTable.waterLevel then
            m.health = m.health - 30
        end

        if m.action == ACT_QUICKSAND_DEATH then
            m.health = 0xff
        end

        if m.health <= 0xff then
            if network_player_connected_count() > 1 then
                m.area.camera.cutscene = 0
                set_mario_spectator(m)
            end
        else
            gLevels[gGlobalSyncTable.level].time = gLevels[gGlobalSyncTable.level].time + 1
        end
    end
end

--- @param m MarioState
local function on_set_mario_action(m)
    if m.action == ACT_VERTICAL_WIND then
        m.vel.y = math.max(m.vel.y, 0)
    end
end

local function on_hud_render()
    if screen then return end

    local water = obj_get_first_with_behavior_id(id_bhvWater)
    if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level and water ~= nil then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        -- tint the screen if Blocky's easter egg is active or the camera is under the water
        if water.oAction == 1 then
            djui_hud_set_adjusted_color(150, 0, 0, clamp(water.oTimer, 0, 100))
            djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
        elseif gLakituState.pos.y < gGlobalSyncTable.waterLevel - 10 then
            switch(water.oAnimState, {
                [FLOOD_WATER] = function()
                    djui_hud_set_adjusted_color(0, 20, 200, 120)
                end,
                [1] = function()
                    djui_hud_set_adjusted_color(200, 200, 200, 220)
                end,
                [FLOOD_LAVA] = function()
                    djui_hud_set_adjusted_color(200, 0, 0, 220)
                end,
                [FLOOD_SAND] = function()
                    djui_hud_set_adjusted_color(254, 193, 121, 220)
                end,
                [4] = function()
                    djui_hud_set_adjusted_color(255, 135, 135, 220)
                end
            })
            djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
        end
    end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local text = if_then_else(gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE, "Type /start to start a round", "0.000 seconds")
    if gNetworkPlayers[0].currAreaSyncValid then
        if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
            text = if_then_else(network_player_connected_count() > 1, "Round starts in " .. tostring(math_floor(gGlobalSyncTable.timer / 30)), "Type /start to start a round")
        elseif gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level then
            text = tostring(string.format("%.3f", gLevels[gGlobalSyncTable.level].time / 30)) .. " seconds"
        end
    end

    local scale = 0.5
    local width = djui_hud_measure_text(text) * scale
    local x = (djui_hud_get_screen_width() - width) * 0.5

    djui_hud_set_adjusted_color(0, 0, 0, 128)
    djui_hud_render_rect(x - 6, 0, width + 12, 16)
    djui_hud_set_adjusted_color(255, 255, 255, 255)
    djui_hud_print_text(text, x, 0, scale)

    hud_render_power_meter(gMarioStates[0].health, djui_hud_get_screen_width() - 64, 0, 64, 64)

    djui_hud_set_font(FONT_HUD)

    djui_hud_render_texture(gTextures.coin, 5, 5, 1, 1)
    djui_hud_print_text("x", 21, 5, 1)
    djui_hud_print_text(tostring(hud_get_value(HUD_DISPLAY_COINS)), 37, 5, 1)

    if gGlobalSyncTable.speedMultiplier ~= 1 then
        djui_hud_print_text(string.format("%.2fx", gGlobalSyncTable.speedMultiplier), 5, 24, 1)
    end
end

local function on_level_init()
    savedStarPoints = 0
    savedSpeedMultiplier = gGlobalSyncTable.speedMultiplier

    -- reset save
    save_file_erase_current_backup_save()
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_CASTLE_GROUNDS then
        save_file_set_flags(SAVE_FLAG_HAVE_VANISH_CAP)
        save_file_set_flags(SAVE_FLAG_HAVE_WING_CAP)
    end
    save_file_set_using_backup_slot(true)

    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if network_is_server() then
            local start = gLevels[gGlobalSyncTable.level].customStartPos
            if start ~= nil then
                gGlobalSyncTable.waterLevel = find_floor_height(start.x, start.y, start.z) - 1200
            else
                -- only sub areas have a weird issue where this function appears to always return the floor lower limit on level init
                gGlobalSyncTable.waterLevel = if_then_else(gLevels[gGlobalSyncTable.level].area == 1, find_floor_height(gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z), gMarioStates[0].pos.y) - 1200
            end
        end

        if game == GAME_VANILLA then
            if gNetworkPlayers[0].currLevelNum == LEVEL_BITS then
                spawn_non_sync_object(
                    id_bhvCustomStaticObject,
                    E_MODEL_CTT,
                    10000, -2000, -40000,
                    function(o) obj_scale(o, 0.5) end
                )
            elseif gNetworkPlayers[0].currLevelNum == LEVEL_WDW then
                set_environment_region(1, -20000)
            elseif gNetworkPlayers[0].currLevelNum == LEVEL_TTC then
                set_ttc_speed_setting(TTC_SPEED_STOPPED)
            end
        end

        local pos = gLevels[gGlobalSyncTable.level].goalPos
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_BONUS then
            spawn_non_sync_object(
                id_bhvFloodFlag,
                E_MODEL_KOOPA_FLAG,
                pos.x, pos.y, pos.z,
                --- @param o Object
                function(o)
                    o.oFaceAngleYaw = pos.a
                end
            )
        elseif game == GAME_VANILLA then
            spawn_non_sync_object(
                id_bhvFinalStar,
                E_MODEL_STAR,
                pos.x, pos.y, pos.z,
                nil
            )
        end

        spawn_non_sync_object(
            id_bhvWater,
            E_MODEL_FLOOD,
            0, gGlobalSyncTable.waterLevel, 0,
            nil
        )
    end
end

-- dynos warps mario back to castle grounds facing the wrong way, likely something from the title screen
local function on_warp()
    local m = gMarioStates[0]
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then
        m.faceAngle.y = m.faceAngle.y + 0x8000

        if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
            play_music(0, SEQUENCE_ARGS(4, SEQ_LEVEL_BOSS_KOOPA_FINAL), 0)
        end
    elseif gLevels[gGlobalSyncTable.level].customStartPos ~= nil then
        local start = gLevels[gGlobalSyncTable.level].customStartPos
        vec3f_copy(m.pos, start)
        m.faceAngle.y = start.a
    end
end

local function on_player_connected()
    if network_is_server() and gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then gGlobalSyncTable.timer = ROUND_COOLDOWN end
end

local function on_start_command(msg)
    if msg == "random" then
        gGlobalSyncTable.level = gLevels[math_random(1, FLOOD_LEVEL_COUNT)]
    else
        local override = tonumber(msg)
        if override ~= nil then
            override = clamp(math_floor(override), 1, FLOOD_LEVEL_COUNT)
            gGlobalSyncTable.level = gMapRotation[override]
        else
            for k, v in pairs(gLevels) do
                if msg:lower() == v.name then
                    gGlobalSyncTable.level = k
                end
            end
        end
    end
    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        network_send(true, { restart = true })
        level_restart()
    else
        round_start()
    end
    return true
end

local function on_speed_command(msg)
    local speed = tonumber(msg)
    if speed ~= nil then
        speed = clampf(speed, 0, 10)
        djui_chat_message_create("Water speed set to " .. speed)
        gGlobalSyncTable.speedMultiplier = speed
        return true
    end
    return false
end

local function on_speedrun_command(msg)
    msg = msg:lower()
    if msg == "off" then
        djui_chat_message_create("Speedrun mode status: \\#ff0000\\OFF")
        speedrunner = SPEEDRUN_MODE_OFF
        return true
    elseif msg == "progress" then
        djui_chat_message_create("Speedrun mode status: \\#00ff00\\Progress Level")
        speedrunner = SPEEDRUN_MODE_PROGRESS
        return true
    elseif msg == "restart" then
        djui_chat_message_create("Speedrun mode status: \\#00ff00\\Restart Level")
        speedrunner = SPEEDRUN_MODE_RESTART
        return true
    end
    return false
end

gServerSettings.skipIntro = 1
gServerSettings.stayInLevelAfterStar = 2

gLevelValues.entryLevel = LEVEL_LOBBY
gLevelValues.floorLowerLimit = -20000
gLevelValues.floorLowerLimitMisc = -20000 + 1000
gLevelValues.floorLowerLimitShadow = -20000 + 1000.0
gLevelValues.fixCollisionBugs = 1
gLevelValues.fixCollisionBugsRoundedCorners = 0

hud_hide()
camera_set_use_course_specific_settings(false)

smlua_text_utils_secret_star_replace(COURSE_PSS, "   Climb The Tower EX")

smlua_audio_utils_replace_sequence(SEQ_LEVEL_BOSS_KOOPA_FINAL, 37, 60, "00_pinball_custom")

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

if network_is_server() then
    hook_chat_command("start", "[random|1-" .. FLOOD_LEVEL_COUNT .. "] to set the level to a random one or a specific one, you can also leave it empty for normal progression.", on_start_command)
    hook_chat_command("speed", "[number] to set the water speed multiplier", on_speed_command)
    hook_chat_command("speedrun", "[off|progress|restart] to change adjustments to singleplayer Flood helpful for speedrunners", on_speedrun_command)
end

for i = 0, MAX_PLAYERS - 1 do
    gPlayerSyncTable[i].finished = false
    gPlayerSyncTable[i].score = 0
    if i == 0 and not cheats then
        gPlayerSyncTable[0].score = tonumber(mod_storage_load("score")) or 0
    end
end

if _G.ommEnabled then
    _G.OmmApi.omm_hud_change_setting(true)
end