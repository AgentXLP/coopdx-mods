-- name: Flood
-- incompatible: gamemode
-- description: Flood v2.0.1\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds a flood escape gamemode\nto sm64ex-coop, you must escape the flood and reach the top of the level before everything is flooded.\n\nSpecial thanks to Mr.Needlemouse64 for the TTC easter egg

FLOOD_WATER = 0
FLOOD_LAVA  = 2
FLOOD_SAND  = 3

LEVEL_LOBBY = LEVEL_CASTLE_GROUNDS
LEVEL_BONUS = LEVEL_PSS

BONUS_LEVELS = 2

ROUND_STATE_INACTIVE = 0
ROUND_STATE_ACTIVE   = 1
ROUND_COOLDOWN       = 600

gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
gGlobalSyncTable.timer = ROUND_COOLDOWN
gGlobalSyncTable.level = LEVEL_BOB
gGlobalSyncTable.waterLevel = -20000
gGlobalSyncTable.speedMultiplier = 1

listedSurvivors = false
savedSpeedMultiplier = 1
score = tonumber(mod_storage_load("score")) or 0
if gServerSettings.enableCheats ~= 0 then score = 0 end

gLevels = {
    [LEVEL_BOB] =            { goalPos = { x = 3304, y = 4242, z = -4603, a = 0x0000 },  speed = 2.5, area = 1, type = FLOOD_WATER, time = 0, points = 1 },
    [LEVEL_WF] =             { goalPos = { x = 414, y = 5325, z = -20, a = 0x0000 },     speed = 4.0, area = 1, type = FLOOD_WATER, time = 0, points = 1 },
    [LEVEL_CCM] =            { goalPos = { x = -478, y = 3471, z = -964, a = 0x0000 },   speed = 5.0, area = 1, type = FLOOD_WATER, time = 0, points = 2, customStartPos = { x = 3336, y = -4200, z = 0, a = 0x0000 }, },
    [LEVEL_BITDW] =          { goalPos = { x = 6772, y = 2867, z = 0, a = -0x4000 },     speed = 4.0, area = 1, type = FLOOD_WATER, time = 0, points = 3 },
    [LEVEL_BBH] =            { goalPos = { x = 655, y = 2867, z = 1824, a = 0x8000 },    speed = 3.5, area = 1, type = FLOOD_WATER, time = 0, points = 3 },
    [LEVEL_LLL] =            { goalPos = { x = 2523, y = 3591, z = -898, a = -0x8000 },  speed = 3.5, area = 2, type = FLOOD_LAVA,  time = 0, points = 3 },
    [LEVEL_SSL] =            { goalPos = { x = 512, y = 4815, z = -551, a = 0x0000 },    speed = 3.0, area = 2, type = FLOOD_SAND,  time = 0, points = 4 },
    [LEVEL_WDW] =            { goalPos = { x = 1467, y = 4096, z = 93, a = -0x4000 },    speed = 4.0, area = 1, type = FLOOD_WATER, time = 0, points = 4 },
    [LEVEL_TTM] =            { goalPos = { x = 1053, y = 2309, z = 305, a = 0x0000 },    speed = 3.0, area = 1, type = FLOOD_WATER, time = 0, points = 5 },
    [LEVEL_THI] =            { goalPos = { x = 1037, y = 4060, z = -2091, a = 0x0000 },  speed = 2.0, area = 1, type = FLOOD_WATER, time = 0, points = 5 },
    [LEVEL_TTC] =            { goalPos = { x = 1354, y = 6190, z = 1340, a = 0x0000 },   speed = 4.0, area = 1, type = FLOOD_WATER, time = 0, points = 7 },
    [LEVEL_BITS] =           { goalPos = { x = 369, y = 6552, z = -6000, a = 0x0000 },   speed = 5.0, area = 1, type = FLOOD_LAVA,  time = 0, points = 6 },
    [LEVEL_BONUS] =          { goalPos = { x = 0, y = 700, z = 0, a = 0x0000 },          speed = 5.0, area = 1, type = FLOOD_LAVA,  time = 0, points = 6 },
    [LEVEL_SL] =             { goalPos = { x = 40, y = 4864, z = 240, a = 0x0000 },      speed = 3.0, area = 1, type = FLOOD_WATER, time = 0, points = 5 },
    [LEVEL_CASTLE_GROUNDS] = { goalPos = { x = 0, y = 7583, z = -4015, a = 0x0000 },     speed = 7.0, area = 1, type = FLOOD_WATER, time = 0, points = 9 }
}

gMapRotation = {
    LEVEL_BOB,
    LEVEL_WF,
    LEVEL_CCM,
    LEVEL_BITDW,
    LEVEL_BBH,
    LEVEL_LLL,
    LEVEL_SSL,
    LEVEL_WDW,
    LEVEL_TTM,
    LEVEL_THI,
    LEVEL_TTC,
    LEVEL_BITS,
    LEVEL_BONUS,
    LEVEL_SL,
    LEVEL_CASTLE_GROUNDS
}

gMapNames = {
    "bob",
    "wf",
    "ccm",
    "bitdw",
    "bbh",
    "lll",
    "ssl",
    "wdw",
    "ttm",
    "thi",
    "ttc",
    "bits",
    "ctt",
    "sl",
    "castle_grounds"
}

-- runs serverside
function round_start()
    gGlobalSyncTable.roundState = ROUND_STATE_ACTIVE
    gGlobalSyncTable.timer = if_then_else(gGlobalSyncTable.level == LEVEL_BONUS, 730, 100)
end

-- runs serverside
function round_end()
    gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
    gGlobalSyncTable.timer = ROUND_COOLDOWN
    gGlobalSyncTable.waterLevel = -20000
end

function level_restart()
    mario_set_full_health(gMarioStates[0])
    gLevels[gGlobalSyncTable.level].time = 0
    warp_restart_level()
end

function server_update()
    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level then
            gGlobalSyncTable.waterLevel = math.min(gGlobalSyncTable.waterLevel + gLevels[gGlobalSyncTable.level].speed * gGlobalSyncTable.speedMultiplier, gLevels[gGlobalSyncTable.level].goalPos.y + 200)

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
                if dead == network_player_connected_count() then
                    gGlobalSyncTable.timer = 0
                end

                if gGlobalSyncTable.timer > 0 then
                    gGlobalSyncTable.timer = gGlobalSyncTable.timer - 1
                else
                    round_end()

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
                        if position > #gMapRotation - BONUS_LEVELS then
                            position = 1
                        end

                        gGlobalSyncTable.level = gMapRotation[position]
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

function update()
    if network_is_server() then server_update() end

    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_LOBBY or gNetworkPlayers[0].currActNum ~= 0 then
            warp_to_level(LEVEL_LOBBY, 1, 0)

            if not listedSurvivors then
                listedSurvivors = true
                local finished = 0
                djui_chat_message_create("Survivors:")
                for i = 0, (MAX_PLAYERS - 1) do
                    if gNetworkPlayers[i].connected and gPlayerSyncTable[i].finished then
                        djui_chat_message_create(gNetworkPlayers[i].name)
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
            warp_to_level(gGlobalSyncTable.level, gLevels[gGlobalSyncTable.level].area, act)
        end
    end
end

--- @param m MarioState
function mario_update(m)
    local color = { r = 0, g = 255, b = 0 }
    if m.health <= 0xff then color = { r = 255, g = 0, b = 0 } end
    network_player_set_description(gNetworkPlayers[m.playerIndex], tostring(gPlayerSyncTable[m.playerIndex].score), color.r, color.g, color.b, 255)

    if m.action == ACT_TWIRLING and gNetworkPlayers[0].currLevelNum == LEVEL_BONUS then m.particleFlags = m.particleFlags | PARTICLE_SPARKLES end

    -- small moveset tweak allowing for better movement
    if m.action == ACT_STEEP_JUMP then m.action = ACT_JUMP end

    if m.playerIndex ~= 0 then return end

    if m.floor.type == SURFACE_WARP or m.floor.type >= SURFACE_PAINTING_WARP_D3 and m.floor.type <= SURFACE_PAINTING_WARP_FC then
        m.floor.type = SURFACE_DEFAULT
    end

    romhack_camera(m)

    -- dialog boxes
    if (m.action == ACT_SPAWN_NO_SPIN_AIRBORNE or m.action == ACT_SPAWN_NO_SPIN_LANDING or m.action == ACT_SPAWN_SPIN_AIRBORNE or m.action == ACT_SPAWN_SPIN_LANDING) and m.pos.y < m.floorHeight + 10 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        mario_set_full_health(m)
        m.peakHeight = m.pos.y
        return
    end

    if gNetworkPlayers[0].currLevelNum == LEVEL_BONUS then
        m.peakHeight = m.pos.y

        local star = obj_get_first_with_behavior_id(id_bhvFinalStar)
        if star ~= nil and obj_check_hitbox_overlap(m.marioObj, star) and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            spawn_mist_particles()
            set_mario_action(m, ACT_JUMBO_STAR_CUTSCENE, 0)
        end

        if m.action == ACT_JUMBO_STAR_CUTSCENE and m.actionTimer == 499 then
            set_mario_spectator(m)
        end
    end

    if ((gNetworkPlayers[0].currLevelNum ~= LEVEL_BONUS and m.pos.y == m.floorHeight)
    or (gNetworkPlayers[0].currLevelNum == LEVEL_BONUS and m.action == ACT_JUMBO_STAR_CUTSCENE)
    or (m.action & ACT_FLAG_ON_POLE) ~= 0)
    and vec3f_dist(m.pos, gLevels[gGlobalSyncTable.level].goalPos) < 500 and not gPlayerSyncTable[0].finished then
        gPlayerSyncTable[0].finished = true

        if gNetworkPlayers[0].currLevelNum ~= LEVEL_BONUS then
            djui_chat_message_create("\\#00ff00\\You escaped the flood!")
            if gNetworkPlayers[0].currLevelNum ~= LEVEL_BITS then
                play_race_fanfare()
            else
                play_secondary_music(SEQ_EVENT_CUTSCENE_COLLECT_STAR, 10, 110, 10)
            end
        else
            djui_chat_message_create("\\#00ff00\\You escaped the \\#ffff00\\final\\#00ff00\\ flood! Congratulations!")
            play_secondary_music(SEQ_EVENT_CUTSCENE_VICTORY, 0, 70, 30)
        end

        if gServerSettings.enableCheats == 0 then
            score = score + gLevels[gGlobalSyncTable.level].points + math.floor(savedSpeedMultiplier - 1)
            mod_storage_save("score", tostring(score))
            gPlayerSyncTable[0].score = score
        end

        djui_chat_message_create("New score: " .. tostring(gPlayerSyncTable[0].score))
    end

    if gPlayerSyncTable[0].finished then
        mario_set_full_health(m)
        if network_player_connected_count() > 1 and m.action ~= ACT_JUMBO_STAR_CUTSCENE then
            set_mario_spectator(m)
        end
    else
        local damage = if_then_else(gGlobalSyncTable.level ~= LEVEL_CASTLE_GROUNDS, 36, 20) -- (0x880 / (2 * 30)) and (0x880 / (3.5 * 30))
        if m.pos.y + 40 < gGlobalSyncTable.waterLevel then
            m.health = m.health - damage
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

function on_hud_render()
    local water = obj_get_first_with_behavior_id(id_bhvWater)
    if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level and gLakituState.pos.y < gGlobalSyncTable.waterLevel - 10 and water ~= nil then
        djui_hud_set_resolution(RESOLUTION_DJUI)
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
            end
        })

        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local text = if_then_else(gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE, "Type /start to start a round", "0.000 seconds")
    if gNetworkPlayers[0].currAreaSyncValid then
        if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
            text = if_then_else(network_player_connected_count() > 1, "Round starts in " .. tostring(math.floor(gGlobalSyncTable.timer / 30)), "Type /start to start a round")
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

    if gGlobalSyncTable.speedMultiplier > 1 then
        djui_hud_set_font(FONT_HUD)
        djui_hud_print_text(tostring(gGlobalSyncTable.speedMultiplier) .. "x", 2, 2, 1)
    end
end

function on_level_init()
    savedSpeedMultiplier = gGlobalSyncTable.speedMultiplier

    if gNetworkPlayers[0].currLevelNum == LEVEL_TTC then
        gLevelValues.fixCollisionBugs = 1
    else
        gLevelValues.fixCollisionBugs = 0
    end

    save_file_erase_current_backup_save()
    save_file_set_using_backup_slot(true)

    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if network_is_server() then
            gGlobalSyncTable.waterLevel = flood_get_start_water_level()
        end

        if gNetworkPlayers[0].currLevelNum == LEVEL_BITS then
            spawn_non_sync_object(
                id_bhvCustomStaticObject,
                E_MODEL_CTT,
                10000, -2000, -40000,
                function(o) obj_scale(o, 0.5) end
            )
        elseif gNetworkPlayers[0].currLevelNum == LEVEL_WDW then
            set_environment_region(1, -20000)
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
        else
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
function on_warp()
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

function on_player_connected()
    if network_is_server() and gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then gGlobalSyncTable.timer = ROUND_COOLDOWN end
end

function on_start_command(msg)
    if msg == "random" then
        gGlobalSyncTable.level = gLevels[math.random(1, #gMapRotation)]
    else
        local override = tonumber(msg)
        if override ~= nil then
            override = clamp(math.floor(override), 1, #gMapRotation)
            gGlobalSyncTable.level = gMapRotation[override]
        else
            for k, v in pairs(gMapNames) do
                if msg:lower() == v then
                    gGlobalSyncTable.level = gMapRotation[k]
                end
            end
        end
    end
    round_start()
    if gNetworkPlayers[0].currLevelNum == gGlobalSyncTable.level and network_player_connected_count() == 1 then
        level_restart()
    end
    return true
end

function on_speed_command(msg)
    local speed = tonumber(msg)
    if speed ~= nil then
        speed = clamp(speed, 0, 10)
        djui_chat_message_create("Water speed set to " .. speed)
        gGlobalSyncTable.speedMultiplier = speed
        return true
    end
    return false
end

gLevelValues.entryLevel = LEVEL_LOBBY
gLevelValues.floorLowerLimit = -20000
gLevelValues.floorLowerLimitMisc = -20000 + 1000
gLevelValues.floorLowerLimitShadow = -20000 + 1000.0

hud_hide()
camera_set_use_course_specific_settings(false)

smlua_text_utils_secret_star_replace(COURSE_PSS, "   Climb The Tower EX")

smlua_audio_utils_replace_sequence(SEQ_LEVEL_BOSS_KOOPA_FINAL, 37, 60, "00_pinball_custom")

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

if network_is_server() then
    hook_chat_command("start", "[random|1-" .. #gMapRotation .. "] to set the level to a random one or a specific one, you can also leave it empty for normal progression.", on_start_command)
    hook_chat_command("speed", "[number] to set the water speed multiplier", on_speed_command)
end

for i = 0, MAX_PLAYERS - 1 do
    gPlayerSyncTable[i].finished = false
    gPlayerSyncTable[i].score = 0
    if i == 0 and gServerSettings.enableCheats == 0 then
        gPlayerSyncTable[0].score = tonumber(mod_storage_load("score")) or 0
    end
end