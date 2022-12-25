-- name: Flood
-- incompatible: gamemode
-- description: Flood v1.1.3\nBy \\#ec7731\\Agent X\\#dddddd\\\n\nThis mod adds a flood escape gamemode to sm64ex-coop, you must escape the flood and reach the top of the level before everything is flooded.
-- climb the tower 2 (climb the level) real

FLOOD_WATER = 0
FLOOD_LAVA = 1
FLOOD_SAND = 2

score = tonumber(mod_storage_load("score")) or 0
if gServerSettings.enableCheats ~= 0 then score = 0 end

levels = {
    [LEVEL_BOB]   = { useFloorHeight = true,  stop = 4200,  speed = 2.5, area = 1, type = FLOOD_WATER, spectate = true,  points = 2, name = "Bob-Omb Battlefield" },
    [LEVEL_WF]    = { useFloorHeight = true,  stop = 5250,  speed = 4.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 2, name = "Whomp's Fortress" },
    [LEVEL_BITDW] = { useFloorHeight = true,  stop = 2750,  speed = 4.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 3, name = "Bowser in the Dark World" },
    [LEVEL_BBH]   = { useFloorHeight = true,  stop = 2500,  speed = 4.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 3, name = "Big Boo's Haunt" },
    [LEVEL_LLL]   = { useFloorHeight = false, stop = 3538,  speed = 4.0, area = 2, type = FLOOD_LAVA,  spectate = true,  points = 3, name = "Lethal Lava Land" },
    [LEVEL_SSL]   = { useFloorHeight = true,  stop = 4800,  speed = 3.0, area = 2, type = FLOOD_SAND,  spectate = true,  points = 4, name = "Shifting Sand Land" },
    [LEVEL_TTM]   = { useFloorHeight = true,  stop = 2300,  speed = 3.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 4, name = "Tall, Tall Mountain" },
    [LEVEL_THI]   = { useFloorHeight = true,  stop = 3890,  speed = 2.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 5, name = "Tiny Huge Island" },
    [LEVEL_BITS]  = { useFloorHeight = true,  stop = 6500,  speed = 4.0, area = 1, type = FLOOD_LAVA,  spectate = false, points = 5, name = "Bowser in the Sky" },
    [LEVEL_PSS]   = { useFloorHeight = true,  stop = 10878, speed = 5.0, area = 1, type = FLOOD_LAVA,  spectate = false, points = 6, name = "Climb The Tower EX" },
    [LEVEL_TTC]   = { useFloorHeight = true,  stop = 6100,  speed = 4.0, area = 1, type = FLOOD_WATER, spectate = true,  points = 8, name = "Tick Tock Clock (Bonus)" }
}

mapRotation = {
    LEVEL_BOB,
    LEVEL_WF,
    LEVEL_BITDW,
    LEVEL_BBH,
    LEVEL_LLL,
    LEVEL_SSL,
    LEVEL_TTM,
    LEVEL_THI,
    LEVEL_BITS,
    LEVEL_PSS,
    LEVEL_TTC
}

-- taken from sm74
sOverrideCameraModes = {
    [CAMERA_MODE_RADIAL]            = true,
    [CAMERA_MODE_OUTWARD_RADIAL]    = true,
    [CAMERA_MODE_CLOSE]             = true,
    [CAMERA_MODE_SLIDE_HOOT]        = true,
    [CAMERA_MODE_PARALLEL_TRACKING] = true,
    [CAMERA_MODE_FIXED]             = true,
    [CAMERA_MODE_8_DIRECTIONS]      = true,
    [CAMERA_MODE_FREE_ROAM]         = true,
    [CAMERA_MODE_SPIRAL_STAIRS]     = true,
}

ROUND_STATE_INACTIVE = 0
ROUND_STATE_ACTIVE   = 1
ROUND_COOLDOWN       = 600

LEVEL_LOBBY = LEVEL_CASTLE_GROUNDS

MAX_HEALTH = 80

gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
gGlobalSyncTable.roundCooldown = ROUND_COOLDOWN
gGlobalSyncTable.map = 1
gGlobalSyncTable.speedMultiplier = 1
gGlobalSyncTable.waterLevel = 0

function map()
    return mapRotation[gGlobalSyncTable.map] -- I don't feel like typing this out 500 times
end

--- @param m MarioState
function get_time(m, map)
    return gPlayerSyncTable[m.playerIndex]["time" .. map]
end

-- runs serverside
function round_start()
    gGlobalSyncTable.roundState = ROUND_STATE_ACTIVE
    -- gGlobalSyncTable.waterLevel = levels[map()].start
    gGlobalSyncTable.roundCooldown = 100
    if gGlobalSyncTable.map == 10 then gGlobalSyncTable.roundCooldown = 740 end
end

-- runs serverside
function round_end()
    gGlobalSyncTable.roundState = ROUND_STATE_INACTIVE
    gGlobalSyncTable.roundCooldown = ROUND_COOLDOWN
end

--- @param m MarioState
function act_dead(m)
    set_mario_animation(m, MARIO_ANIM_DYING_ON_STOMACH)
    m.marioBodyState.eyeState = MARIO_EYES_DEAD
    m.faceAngle.x = 0
    m.faceAngle.z = 0

    local water = obj_get_first_with_behavior_id(id_bhvWater)
    if water ~= nil then m.pos.y = water.oPosY - 25 end
    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
end

ACT_DEAD = allocate_mario_action(ACT_GROUP_CUTSCENE)

warpCooldown = 0
function warp(level, area, act)
    if warpCooldown == 0 then
        warpCooldown = 5
        warp_to_level(level, area, act)
    end
end

lateJoin = true
function reset_stats()
    if lateJoin then
        lateJoin = false
        return
    end
    gPlayerSyncTable[0].won = false
    gPlayerSyncTable[0].health = MAX_HEALTH
    reset_spectator()
end

--- @param m MarioState
function romhack_camera(m)
    if sOverrideCameraModes[m.area.camera.mode] == nil then return end

    if (m.controller.buttonPressed & L_TRIG) ~= 0 then center_rom_hack_camera() end

    set_camera_mode(m.area.camera, CAMERA_MODE_ROM_HACK, 0)
end

function server_update()
    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        if network_player_connected_count() > 1 then
            if gGlobalSyncTable.roundCooldown > 0 then
                gGlobalSyncTable.roundCooldown = gGlobalSyncTable.roundCooldown - 1
            else
                round_start()
            end
        end

        if gGlobalSyncTable.roundCooldown == 30 or gGlobalSyncTable.roundCooldown == 60 or gGlobalSyncTable.roundCooldown == 90 then
            play_sound(SOUND_MENU_CHANGE_SELECT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
        elseif gGlobalSyncTable.roundCooldown == 11 then
            play_sound(SOUND_GENERAL_RACE_GUN_SHOT, gMarioStates[0].marioObj.header.gfx.cameraToObject)
        end
    else
        gGlobalSyncTable.waterLevel = gGlobalSyncTable.waterLevel + levels[map()].speed * gGlobalSyncTable.speedMultiplier

        local survivors = 0
        for i = 0, network_player_connected_count() - 1 do
            if gPlayerSyncTable[i].health > 0 then survivors = survivors + 1 end
        end
        local winners = 0
        for i = 0, network_player_connected_count() - 1 do
            if gPlayerSyncTable[i].won then winners = winners + 1 end
        end

        if survivors == 0 then round_end() end
        if winners == survivors then
            if gGlobalSyncTable.roundCooldown > 0 then gGlobalSyncTable.roundCooldown = gGlobalSyncTable.roundCooldown - 1
            else round_end() end
        end
    end
end

function update()
    if not gNetworkPlayers[0].currAreaSyncValid then return end
    if network_is_server() then server_update() end

    if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
        if gNetworkPlayers[0].currLevelNum ~= LEVEL_LOBBY then warp(LEVEL_LOBBY, 1, 0) end
        reset_stats()
    elseif gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if gNetworkPlayers[0].currLevelNum ~= map() then
            reset_stats()
            warp(map(), levels[map()].area, 6)
            gPlayerSyncTable[0]["time" .. gGlobalSyncTable.map] = 0
        end
    end

    if warpCooldown > 0 then warpCooldown = warpCooldown - 1 end
end

--- @param m MarioState
function mario_update(m)
    local color = { r = 0, g = 255, b = 0 }
    if m.action == ACT_DEAD then color = { r = 255, g = 0, b = 0 } end
    network_player_set_description(gNetworkPlayers[m.playerIndex], tostring(gPlayerSyncTable[m.playerIndex].score), color.r, color.g, color.b, 255)
    sparkle_if_twirling(m)

    -- shh
    if m.action == ACT_STEEP_JUMP then m.action = ACT_JUMP end

    if m.playerIndex ~= 0 then return end

    m.health = 0x880
    romhack_camera(m)
    if gNetworkPlayers[0].currLevelNum == LEVEL_PSS or gNetworkPlayers[0].currLevelNum == LEVEL_LOBBY then disable_fall_damage(m) end

    -- dialog boxes
    if (m.action == ACT_SPAWN_NO_SPIN_AIRBORNE or m.action == ACT_SPAWN_NO_SPIN_LANDING or m.action == ACT_SPAWN_SPIN_AIRBORNE or m.action == ACT_SPAWN_SPIN_LANDING) and m.pos.y < m.floorHeight + 10 then
        set_mario_action(m, ACT_FREEFALL, 0)
    end

    if not gNetworkPlayers[0].currAreaSyncValid or gNetworkPlayers[0].currLevelNum ~= map() then return end

    if m.hurtCounter > 0 and not gPlayerSyncTable[0].won then
        gPlayerSyncTable[0].health = gPlayerSyncTable[0].health - m.hurtCounter * 3
        m.hurtCounter = 0
    end
    if m.healCounter > 0 and not gPlayerSyncTable[0].won and gPlayerSyncTable[0].health < MAX_HEALTH and gPlayerSyncTable[0].health > 0 then
        gPlayerSyncTable[0].health = gPlayerSyncTable[0].health + m.healCounter * 2
        m.healCounter = 0
        play_sound(SOUND_MENU_POWER_METER, m.marioObj.header.gfx.cameraToObject)
    end

    if m.pos.y + 40 < gGlobalSyncTable.waterLevel and not gPlayerSyncTable[0].won then
        if gPlayerSyncTable[0].health > 0 then gPlayerSyncTable[0].health = gPlayerSyncTable[0].health - 1.5 end
    end
    if (m.floor.type == SURFACE_DEATH_PLANE or m.floor.type == SURFACE_VERTICAL_WIND) and m.pos.y < m.floorHeight + 3000 and gNetworkPlayers[0].currLevelNum ~= LEVEL_TTC then
        gPlayerSyncTable[0].health = 0
    end

    gPlayerSyncTable[0].health = clamp(gPlayerSyncTable[m.playerIndex].health, 0, MAX_HEALTH)

    if gPlayerSyncTable[0].health == 0 then
        if gNetworkPlayers[0].currAreaIndex == levels[map()].area then update_spectator(m) end
        if m.action ~= ACT_DEAD then
            m.pos.y = gGlobalSyncTable.waterLevel
            set_mario_action(m, ACT_DEAD, 0)
        end
    end

    if gNetworkPlayers[0].currAreaIndex ~= levels[map()].area then
        gPlayerSyncTable[0].health = 0
        return
    end

    if m.pos.y >= levels[map()].stop and not gPlayerSyncTable[0].won and m.pos.y == m.floorHeight then
        gPlayerSyncTable[0].won = true

        if gNetworkPlayers[0].currLevelNum ~= LEVEL_PSS then
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
            score = score + levels[map()].points
            mod_storage_save("score", tostring(score))
            gPlayerSyncTable[0].score = score
        end

        djui_chat_message_create("New score: " .. tostring(gPlayerSyncTable[0].score))
    end

    if gPlayerSyncTable[0].won then
        gPlayerSyncTable[0].health = MAX_HEALTH
        if m.floor.type == SURFACE_DEATH_PLANE then m.floor.type = SURFACE_DEFAULT end
        if network_player_connected_count() > 1 and levels[map()].spectate then
            set_mario_action(m, ACT_DISAPPEARED, 0)
            m.pos.y = m.pos.y + 1000
            update_spectator(m)
        end
    else
        gPlayerSyncTable[0]["time" .. gGlobalSyncTable.map] = gPlayerSyncTable[0]["time" .. gGlobalSyncTable.map] + 1
    end
end

function before_phys_step(m)
    if m.playerIndex ~= 0 then return end

    local water = obj_get_first_with_behavior_id(id_bhvWater)
    if water ~= nil and m.pos.y + 40 < water.oPosY and gNetworkPlayers[m.playerIndex].currLevelNum == map() then
        m.vel.y = m.vel.y + 2
    end
end

function on_hud_render()
    if gPlayerSyncTable[0]["time" .. gGlobalSyncTable.map] == nil then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local text = if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_LOBBY, "Type /start to start a round", "0.000 seconds")
    if gNetworkPlayers[0].currAreaSyncValid then
        if gGlobalSyncTable.roundState == ROUND_STATE_INACTIVE then
            text = if_then_else(network_player_connected_count() > 1, "Round starts in " .. tostring(math.floor(gGlobalSyncTable.roundCooldown / 30)), "Type /start to start a round")
        else
            text = tostring(string.format("%.3f", gPlayerSyncTable[0]["time" .. gGlobalSyncTable.map] / 30)) .. " seconds"
        end
    end

    local scale = 0.5
    local width = djui_hud_measure_text(text) * scale
    local x = (djui_hud_get_screen_width() - width) * 0.5

    djui_hud_set_adjusted_color(0, 0, 0, 128)
    djui_hud_render_rect(x - 6, 0, width + 12, 16)
    djui_hud_set_adjusted_color(255, 255, 255, 255)
    djui_hud_print_text(text, x, 0, scale)

    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE and gNetworkPlayers[0].currLevelNum ~= LEVEL_LOBBY and gPlayerSyncTable[0].health > 0 then
        x = djui_hud_get_screen_width() * 0.5
        local y = 20
        width = 120

        local brightness = 0
        djui_hud_set_color(brightness, brightness, brightness, 200)
        djui_hud_render_rect(x - (width * 0.5), y, width, 10)
        local health = gPlayerSyncTable[0].health / MAX_HEALTH
        local blend = { r = 0, g = 255, b = 0 }
        if gPlayerSyncTable[0].health > MAX_HEALTH * 0.5 then
            blend = color_lerp({ r = 255, g = 255, b = 0 }, { r = 0, g = 255, b = 0 }, health * 2)
        else
            blend = color_lerp({ r = 255, g = 0, b = 0 }, { r = 255, g = 255, b = 0 }, (health - 0.5) * 2)
        end
        djui_hud_set_color(blend.r, blend.g, blend.b, 255)
        djui_hud_render_texture(get_texture_info("gradient"), x - (width * 0.5), y, health * (width / 64), 10 / 64)
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].health = 0
    gPlayerSyncTable[m.playerIndex].won = false

    if m.playerIndex == 0 then
        gPlayerSyncTable[0].score = score
    else
        gPlayerSyncTable[m.playerIndex].score = 0
    end

    for k, v in pairs(mapRotation) do
        gPlayerSyncTable[m.playerIndex]["time" .. k] = 0
    end
end

--- @param m MarioState
--- @param o Object
function allow_interact(m, o)
    if gNetworkPlayers[m.playerIndex].currLevelNum == LEVEL_CASTLE_GROUNDS and o.oInteractType ~= INTERACT_PLAYER then return false end
    if obj_has_behavior_id(o, id_bhvStar) ~= 0
    or obj_has_behavior_id(o, id_bhvDoorWarp) ~= 0
    or obj_has_behavior_id(o, id_bhvWarp) ~= 0 then return false end

    return true
end

function on_level_init()
    save_file_erase_current_backup_save()
    save_file_set_using_backup_slot(true)

    if gGlobalSyncTable.roundState == ROUND_STATE_ACTIVE then
        if gNetworkPlayers[0].currLevelNum == map() then
            gGlobalSyncTable.waterLevel = if_then_else(levels[map()].useFloorHeight, gMarioStates[0].floorHeight - 1200, gMarioStates[0].spawnInfo.startPos.y - 1200)

            spawn_non_sync_object(
                id_bhvWater,
                E_MODEL_FLOOD,
                0, gGlobalSyncTable.waterLevel, 0,
                nil
            )
        end

        if gNetworkPlayers[0].currLevelNum == LEVEL_BITS then
            spawn_non_sync_object(
                id_bhvCustomStaticObject,
                E_MODEL_CTT,
                10000, -2000, -40000,
                function(o) obj_scale(o, 0.5) end
            )

            spawn_non_sync_object(
                id_bhvFinalStar,
                E_MODEL_STAR,
                370, 7100, -6000,
                function(o) obj_scale(o, 3.5) end
            )
        end
    end
end

function on_round_state_changed(tag, oldVal, newVal)
    if newVal == ROUND_STATE_INACTIVE and oldVal == ROUND_STATE_ACTIVE then
        local won = 0
        djui_chat_message_create(if_then_else(gGlobalSyncTable.map ~= 10, "Survivors:", "\\#ffff00\\Ultimate Survivors:"))
        for i = 0, network_player_connected_count() - 1 do
            if gPlayerSyncTable[i].won then
                djui_chat_message_create(gNetworkPlayers[i].name)
                won = won + 1
            end
            gPlayerSyncTable[i].won = false
        end
        if won ~= 0 then
            gGlobalSyncTable.map = gGlobalSyncTable.map + 1
            if gGlobalSyncTable.map >= 11 then gGlobalSyncTable.map = 1 end
        else
            djui_chat_message_create("\\#ff0000\\None")
        end
    end
end


function on_start_command(msg)
    if msg == "random" then
        gGlobalSyncTable.map = math.random(1, 10)
    else
        local override = tonumber(msg)
        if override == 11 then
            gGlobalSyncTable.map = 11
            round_start()
            return true
        end
        if override ~= nil and override <= 10 and override > 0 then
            override = math.floor(override)
            gGlobalSyncTable.map = override
        end
    end
    if gNetworkPlayers[0].currLevelNum ~= map() then round_start() end
    return true
end

function on_speed_command(msg)
    local speed = tonumber(msg)
    if speed ~= nil then
        speed = clamp(speed, 1, 10)
        djui_chat_message_create("Water speed set to " .. speed)
        gGlobalSyncTable.speedMultiplier = speed
        return true
    end
    return false
end

function print_scoreboard(map)
    local descending = {}
    for i = 0, network_player_connected_count() - 1 do
        table.insert(descending, gPlayerSyncTable[i]["time" .. map])
    end
    table.sort(descending, function(a, b) return a[2] > b[2] end)
    for i = 0, network_player_connected_count() - 1 do
        djui_chat_message_create(levels[mapRotation[map]].name .. " - " .. gNetworkPlayers[i].name .. "\\#ffffff\\: " .. tostring(string.format("%.3f", gPlayerSyncTable[0]["time" .. map] / 30)) .. " seconds")
    end
end

function on_scoreboard_command(msg)
    local map = tonumber(msg) or 1
    if map < 1 then map = 1 end

    if msg == "all" then
        for i = 1, 10 do
            print_scoreboard(i)
        end
    else
        print_scoreboard(map)
    end
    return true
end

hud_hide()
camera_set_use_course_specific_settings(false)

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_DEATH, function() return false end)
hook_event(HOOK_ON_PAUSE_EXIT,  function() return false end)

hook_mario_action(ACT_DEAD, act_dead, INTERACT_PLAYER)

hook_on_sync_table_change(gGlobalSyncTable, "roundState", 0, on_round_state_changed)

hook_chat_command("scoreboard", "[1-10] to show the scoreboard of one of the levels", on_scoreboard_command)

if network_is_server() then
    hook_chat_command("start", "[random|1-10] to set the level to a random one or a specific one, you can also leave it empty for normal progression.", on_start_command)
    hook_chat_command("speed", "[number] to set the water speed multiplier", on_speed_command)
end