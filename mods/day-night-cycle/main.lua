-- name: Day Night Cycle
-- incompatible: light
-- description: Day Night Cycle v1.1\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a fully featured day night cycle system with night, sunrise, day and sunset to sm64ex-coop. Days last 24 minutes and you can switch to and from 24 hour time with /ampm\nSpecial thanks to \\#00ffff\\AngelicMiracles \\#dcdcdc\\for the sunset, sunrise and night time skyboxes

_G.DayNightCycle = {}

if VERSION_NUMBER < 35 then return end

SECOND = 30
MINUTE = SECOND * 60

HOUR_SUNRISE_START = 4
HOUR_SUNRISE_END = 5
HOUR_SUNRISE_DURATION = HOUR_SUNRISE_END - HOUR_SUNRISE_START

HOUR_SUNSET_START = 19
HOUR_SUNSET_END = 20
HOUR_SUNSET_DURATION = HOUR_SUNSET_END - HOUR_SUNSET_START

HOUR_DAY_START = 6
HOUR_NIGHT_START = 21

local LIGHT_DARK = 0.1
local LIGHT_BRIGHT = 1

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

_G.DayNightCycle.gExcludedDayNightLevels = gExcludedDayNightLevels
_G.DayNightCycle.enabled = true

useAMPM = true
if mod_storage_load("ampm") == nil then
    mod_storage_save("ampm", tostring(useAMPM))
else
    useAMPM = mod_storage_load("ampm") == "true"
end

saved = false
autoSaveTimer = 0
hideTime = false

-- localize functions to improve performance
local math_floor,djui_hud_set_render_behind_hud,clampf,set_override_envfx,obj_get_first_with_behavior_id,set_lighting_dir,djui_hud_set_resolution,djui_hud_set_color,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,hud_is_hidden,djui_hud_measure_text,djui_hud_print_text,network_is_server,djui_chat_message_create,network_is_moderator,mod_storage_save,play_sound = math.floor,djui_hud_set_render_behind_hud,clampf,set_override_envfx,obj_get_first_with_behavior_id,set_lighting_dir,djui_hud_set_resolution,djui_hud_set_color,djui_hud_get_screen_height,djui_hud_get_screen_width,djui_hud_render_rect,djui_hud_set_font,hud_is_hidden,djui_hud_measure_text,djui_hud_print_text,network_is_server,djui_chat_message_create,network_is_moderator,mod_storage_save,play_sound

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
    if not _G.DayNightCycle.enabled then return end

    djui_hud_set_render_behind_hud(true)

    local minutes = (gGlobalSyncTable.time / MINUTE) % 24

    -- manages brightness level depending on time of day
    local light = LIGHT_DARK
    if minutes >= HOUR_SUNRISE_START and minutes <= HOUR_SUNRISE_END + 0.25 then
        light = lerp(0.1, 1, clampf((minutes - HOUR_SUNRISE_START) / (HOUR_SUNRISE_DURATION + 0.25), 0, 1))
    elseif minutes >= HOUR_SUNSET_START and minutes <= HOUR_NIGHT_START then
        light = lerp(1, 0.1, clampf((minutes - HOUR_SUNSET_START) / (HOUR_NIGHT_START - HOUR_SUNSET_START), 0, 1))
    end
    if minutes < HOUR_SUNRISE_START or minutes > HOUR_NIGHT_START then
        light = LIGHT_DARK
    elseif minutes > HOUR_SUNRISE_END + 0.25 and minutes < HOUR_SUNSET_START then
        light = LIGHT_BRIGHT
    end

    -- blizzard effect at night in snow levels
    if (minutes > 20 or minutes < 5.5) and gMarioStates[0].area.terrainType == TERRAIN_SNOW and show_day_night_cycle() then
        set_override_envfx(ENVFX_SNOW_BLIZZARD)
    else
        set_override_envfx(-1)
    end

    local actSelector = obj_get_first_with_behavior_id(id_bhvActSelector)

    set_lighting_dir(1, -(1 - light))
    set_lighting_dir(2, -(1 - light))

    if actSelector == nil and (show_day_night_cycle() or (gNetworkPlayers[0].currLevelNum == LEVEL_DDD or gNetworkPlayers[0].currLevelNum == LEVEL_WDW)) then -- DDD and JRB are both levels that have subareas connected by instant warps
        djui_hud_set_resolution(RESOLUTION_DJUI)

        -- lerp between an orange and blue depending on how late it is
        local color = { r = 0, g = 0, b = 10 }
        if minutes > 12 then
            color = color_lerp({ r = 0, g = 0, b = 10 }, { r = 20, g = 10, b = 0 }, clampf(((light - 0.1) / 0.9) * 3, 0, 1))
        end

        djui_hud_set_color(color.r, color.g, color.b, 255 * clampf(1 - light, 0, 0.5))
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end

    if actSelector ~= nil or gNetworkPlayers[0].currActNum == 99 or hideTime then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_TINY)

    local scale = 1

    local text = get_time_string()

    local hidden = hud_is_hidden()
    local x = if_then_else(hidden, (djui_hud_get_screen_width() * 0.5) - (djui_hud_measure_text(text) * (0.5 * scale)), 24)
    local y = if_then_else(hidden, (djui_hud_get_screen_height() - 20), 32)

    -- outlined text
    djui_hud_set_color(0, 0, 0, 255)
    djui_hud_print_text(text, x - 1, y, scale)
    djui_hud_print_text(text, x + 1, y, scale)
    djui_hud_print_text(text, x, y - 1, scale)
    djui_hud_print_text(text, x, y + 1, scale)
    if minutes < HOUR_DAY_START or minutes >= HOUR_NIGHT_START then
        djui_hud_set_color(0, 0, 255, 255)
    else
        djui_hud_set_color(255, 255, 0, 255)
    end
    djui_hud_print_text(text, x, y, scale)
end

local function on_level_init()
    if not _G.DayNightCycle.enabled then return end

    hideTime = false

    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS and gNetworkPlayers[0].currActNum == 99 then
        if gMarioStates[0].action ~= ACT_END_WAVING_CUTSCENE then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 17.25)
        else
            gGlobalSyncTable.time = (get_day_count() + 1) * (MINUTE * 24) + (MINUTE * 6.25)
        end
    end
end

local function on_warp()
    if not _G.DayNightCycle.enabled then return end

    playingNightMusic = false

    if network_is_server() then save_time() end
end

local function on_time_command(msg)
    if not _G.DayNightCycle.enabled then
        djui_chat_message_create("Day Night Cycle is disabled.")
        return true
    end

    if not (network_is_moderator() or network_is_server()) then
        djui_chat_message_create("\\#d86464\\You do not have permission to run this command.")
        return true
    end

    local args = split(msg)
    if args[1] == nil then return false end

    if args[1] == "set" then
        if args[2] == nil then
            return false
        end
        if args[2] == "morning" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 6)
        elseif args[2] == "day" or args[2] == "noon" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 12)
        elseif args[2] == "night" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 21)
        elseif args[2] == "midnight" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24)
        elseif args[2] == "sunrise" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 5)
        elseif args[2] == "sunset" then
            gGlobalSyncTable.time = get_day_count() * (MINUTE * 24) + (MINUTE * 20)
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
    elseif args[1] == "curse" and network_is_server() and gGlobalSyncTable.fought then
        mod_storage_save("fought", "false")
        gGlobalSyncTable.fought = false
        play_sound(SOUND_MENU_BOWSER_LAUGH, gMarioStates[0].marioObj.header.gfx.cameraToObject)
        return true
    end

    return false
end

local function on_ampm_command()
    if not _G.DayNightCycle.enabled then
        djui_chat_message_create("Day Night Cycle is disabled.")
        return true
    end

    useAMPM = not useAMPM
    mod_storage_save("ampm", tostring(useAMPM))
    return true
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)

hook_chat_command("time", "\\#00ffff\\[set|add|scale|query]", on_time_command)
hook_chat_command("ampm", "to toggle AM/PM time on and off", on_ampm_command)