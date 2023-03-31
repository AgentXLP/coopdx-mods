-- name: Day Night Cycle
-- incompatible: light
-- description: Day Night Cycle\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a fully featured day night cycle system with night, sunrise, day and sunset to sm64ex-coop. Days last 24 minutes and you can switch to and from 24 hour time with /ampm\n\nSpecial thanks to \\#00ffff\\AngelicMiracles \\#dcdcdc\\for the sunset and night time skyboxes\n\nSpecial thanks to \\#00ffff\\Blocky \\#dcdcdc\\for the music changing instruments at night

if VERSION_NUMBER < 32 then return end

local SECOND = 30
MINUTE = SECOND * 60

gGlobalSyncTable.time = load_time()
gGlobalSyncTable.timeScale = 1

-- levels where the dark effect does not render
gExcludedDayNightLevels = {
    [LEVEL_CASTLE] = true,
    [LEVEL_PSS] = true,
    [LEVEL_BBH] = true,
    [LEVEL_BITDW] = true,
    [LEVEL_BOWSER_1] = true,
    [LEVEL_HMC] = true,
    [LEVEL_LLL] = true,
    [LEVEL_COTMC] = true,
    [LEVEL_VCUTM] = true,
    [LEVEL_BITFS] = true,
    [LEVEL_BOWSER_2] = true,
    [LEVEL_BITS] = true,
    [LEVEL_BOWSER_3] = true,
    [LEVEL_TTC] = true,
    [LEVEL_ENDING] = true
}

_G.gExcludedDayNightLevels = gExcludedDayNightLevels

local useAMPM = true
if mod_storage_load("ampm") == nil then
    mod_storage_save("ampm", tostring(useAMPM))
else
    useAMPM = mod_storage_load("ampm") == "true"
end

local light = 0.1
local saved = false
local autoSaveTimer = 0
local playingNightMusic = false

-- localize functions to improve performance
local math_floor = math.floor
local djui_chat_message_create = djui_chat_message_create
local djui_hud_get_screen_height = djui_hud_get_screen_height
local djui_hud_get_screen_width = djui_hud_get_screen_width
local djui_hud_is_pause_menu_created = djui_hud_is_pause_menu_created
local djui_hud_print_text = djui_hud_print_text
local djui_hud_render_rect = djui_hud_render_rect
local djui_hud_set_color = djui_hud_set_color
local djui_hud_set_font = djui_hud_set_font
local djui_hud_set_render_behind_hud = djui_hud_set_render_behind_hud
local djui_hud_set_resolution = djui_hud_set_resolution
local fade_volume_scale = fade_volume_scale
local mod_storage_save = mod_storage_save
local network_is_moderator = network_is_moderator
local network_is_server = network_is_server
local smlua_audio_utils_replace_sequence = smlua_audio_utils_replace_sequence
local clampf = clampf
local set_lighting_dir = set_lighting_dir
local set_override_envfx = set_override_envfx
local obj_get_first_with_behavior_id = obj_get_first_with_behavior_id
local set_background_music = set_background_music
local lerp = lerp

local function get_time_string()
    local minutes = (gGlobalSyncTable.time / MINUTE) % 24
    local formattedMinutes = math_floor(minutes)
    local seconds = math_floor(gGlobalSyncTable.time / SECOND) % 60

    if useAMPM then
        if formattedMinutes == 0 then
            formattedMinutes = 12
        elseif formattedMinutes > 12 then
            formattedMinutes = formattedMinutes - 12
        end
    end

    return math_floor(formattedMinutes) .. ":" .. format_number(seconds) .. if_then_else(useAMPM, if_then_else(minutes < 12, " AM", " PM"), "")
end

local function on_hud_render()
    -- increment time serversided, autosave as well
    if network_is_server() then
        gGlobalSyncTable.time = gGlobalSyncTable.time + gGlobalSyncTable.timeScale

        autoSaveTimer = (autoSaveTimer + 1) % SECOND * 30
        if autoSaveTimer == 0 then
            save_time()
        end
    end

    local minutes = (gGlobalSyncTable.time / MINUTE) % 24

    -- manages brightness level depending on time of day
    if minutes >= 5 and minutes <= 7 then
        light = lerp(0.1, 1, clampf((minutes - 5) / 2, 0, 1))
    elseif minutes >= 18 and minutes <= 20 then
        light = lerp(1, 0.1, clampf((minutes - 18) / 2, 0, 1))
    end
    if minutes < 5 or minutes > 20 then
        light = 0.1
    elseif minutes > 7 and minutes < 18 then
        light = 1
    end

    -- blizzard effect at night in snow levels
    if (minutes > 20 or minutes < 5.5) and gMarioStates[0].area.terrainType == TERRAIN_SNOW and show_day_night_cycle() then
        set_override_envfx(ENVFX_SNOW_BLIZZARD)
    else
        set_override_envfx(-1)
    end

    -- change music depending on time of day
    if gNetworkPlayers[0].currActNum ~= 99 and show_day_night_cycle() and gMarioStates[0].area ~= nil and gMarioStates[0].area.musicParam2 ~= SEQ_SOUND_PLAYER then
        if minutes >= 19.75 and minutes < 20 then
            fade_volume_scale(0, 127 * (1 - ((minutes - 19.75) * 4)), 1)
        elseif minutes >= 6.75 and minutes < 7 then
            fade_volume_scale(0, 127 * (1 - ((minutes - 6.75) * 4)), 1)
        end

        if (minutes >= 20 or minutes < 7) and not playingNightMusic then
            playingNightMusic = true
            fade_volume_scale(0, 127, 450)
            set_background_music(0, SEQUENCE_ARGS(4, gMarioStates[0].area.musicParam2 + 0x1F), 450)
        elseif minutes >= 7 and minutes < 20 and playingNightMusic then
            playingNightMusic = false
            set_background_music(0, SEQUENCE_ARGS(4, gMarioStates[0].area.musicParam2), 0)
        end
    end

    local actSelector = obj_get_first_with_behavior_id(id_bhvActSelector)

    djui_hud_set_render_behind_hud(true)

    set_lighting_dir(1, -(1 - light))
    set_lighting_dir(2, -(1 - light))

    if actSelector == nil and (show_day_night_cycle() or (gNetworkPlayers[0].currLevelNum == LEVEL_DDD or gNetworkPlayers[0].currLevelNum == LEVEL_WDW)) then -- DDD and JRB are both levels that have subareas connected by instant warps
        djui_hud_set_resolution(RESOLUTION_DJUI)

        -- lerp between an orange and blue depending on how late it is
        local color = color_lerp({ r = 0, g = 0, b = 5 }, { r = 10, g = 5, b = 0 }, clampf(((light - 0.1) / 0.9) * 3, 0, 1))
        djui_hud_set_color(color.r, color.g, color.b, 255 * ((1 - light) - (0.1 * (color.b) / 5)))
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end

    if djui_hud_is_pause_menu_created() then
        if network_is_server() then
            if not saved then
                save_time()
                saved = true
            end
        end
        return
    else
        saved = false
    end

    if actSelector ~= nil or common_hud_hide_requirements() then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local scale = 0.5
    local text = get_time_string()

    -- outlined text
    djui_hud_set_color(0, 0, 0, 255)
    djui_hud_print_text(text, 24 - 1, 32, scale)
    djui_hud_print_text(text, 24 + 1, 32, scale)
    djui_hud_print_text(text, 24, 32 - 1, scale)
    djui_hud_print_text(text, 24, 32 + 1, scale)
    if minutes < 7 or minutes >= 20 then
        djui_hud_set_color(0, 0, 255, 255)
    else
        djui_hud_set_color(255, 255, 0, 255)
    end
    djui_hud_print_text(text, 24, 32, scale)
end

local function on_level_init()
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS and gNetworkPlayers[0].currActNum == 99 then
        if gMarioStates[0].action ~= ACT_END_WAVING_CUTSCENE then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 17.25)
        else
            gGlobalSyncTable.time = (get_day_count() + 1) * (MINUTE * 24) + (MINUTE * 6.25)
        end
    end
end

local function on_warp()
    playingNightMusic = false

    if network_is_server() then save_time() end
end

local function on_time_command(msg)
    if not (network_is_moderator() or network_is_server()) then
        djui_chat_message_create("You do not have permission to run this command.")
        return true
    end

    local args = split(msg)
    if args[1] == nil then return false end

    if args[1] == "set" then
        if args[2] == nil then
            return false
        end
        if args[2] == "morning" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 7)
        elseif args[2] == "day" or args[2] == "noon" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 12)
        elseif args[2] == "night" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 20)
        elseif args[2] == "midnight" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24)
        elseif args[2] == "sunrise" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 6)
        elseif args[2] == "sunset" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 18.5)
        else
            local amount = tonumber(args[2])
            if amount == nil then
                return false
            end
            gGlobalSyncTable.time = amount * SECOND
        end

        djui_chat_message_create("Time set to " .. math_floor(gGlobalSyncTable.time / SECOND))

        if network_is_server() then
            save_time()
        end
        return true
    elseif args[1] == "add" then
        local amount = tonumber(args[2])
        if amount == nil then
            return false
        end
        gGlobalSyncTable.time = gGlobalSyncTable.time + (amount * SECOND)

        djui_chat_message_create("Time set to " .. math_floor(gGlobalSyncTable.time / SECOND))

        if network_is_server() then
            save_time()
        end
        return true
    elseif args[1] == "scale" then
        local scale = tonumber(args[2])
        if scale == nil then
            return false
        end
        gGlobalSyncTable.timeScale = scale

        djui_chat_message_create("Time scale set to " .. scale)

        if network_is_server() then
            save_time()
        end
        return true
    elseif args[1] == "query" then
        djui_chat_message_create(string.format("Time is %d (%s), day %d", math_floor(gGlobalSyncTable.time / SECOND), get_time_string(), get_day_count()))
        if network_is_server() then
            save_time()
        end
        return true
    end

    return false
end

local function on_ampm_command()
    useAMPM = not useAMPM
    mod_storage_save("ampm", tostring(useAMPM))
    return true
end

smlua_audio_utils_replace_sequence(0x0A + 0x1F, 0x14, 80, "0A_level_spooky")
smlua_audio_utils_replace_sequence(0x0C + 0x1F, 0x14, 80, "0C_level_underground")
smlua_audio_utils_replace_sequence(0x0E + 0x1F, 0x14, 80, "0E_event_powerup")
smlua_audio_utils_replace_sequence(0x0F + 0x1F, 0x14, 80, "0F_event_metal_cap")
smlua_audio_utils_replace_sequence(0x03 + 0x1F, 0x14, 80, "03_level_grass")
smlua_audio_utils_replace_sequence(0x05 + 0x1F, 0x14, 80, "05_level_water")
smlua_audio_utils_replace_sequence(0x06 + 0x1F, 0x14, 80, "06_level_hot")
smlua_audio_utils_replace_sequence(0x08 + 0x1F, 0x14, 80, "08_level_snow")
smlua_audio_utils_replace_sequence(0x09 + 0x1F, 0x14, 80, "09_level_slide")
smlua_audio_utils_replace_sequence(0x14 + 0x1F, 0x14, 80, "14_event_race")
smlua_audio_utils_replace_sequence(0x16 + 0x1F, 0x14, 80, "16_event_boss")

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)

hook_chat_command("time", "[set|add|scale|query] [number] to set the time or add to the time in seconds (minutes in in-game time) or get the time in seconds (minutes in in-game time)", on_time_command)
hook_chat_command("ampm", "to toggle AM/PM time on and off", on_ampm_command)