-- name: Weather Cycle DX
-- incompatible: weather environment-tint
-- description: Weather Cycle DX v1.1.4\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a weather cycle system with cloudy skies, rain, and storms to sm64coopdx. It uses Day Night Cycle DX as a base library, meaning you need\nto have the mod enabled in order to use this one. There is also a toggleable\nAurora Borealis that starts after midnight.\n\nSpecial thanks to Floralys for the original concept.\nSpecial thanks to \\#344ee1\\eros71\\#dcdcdc\\ for saving the mod!

if not check_dnc_compatible() then return end

-- localize functions to improve performance
local math_tointeger,mod_storage_load_number,network_is_server,math_random,tonumber,get_skybox,set_override_envfx,network_check_singleplayer_pause,get_network_area_timer,play_transition,obj_get_first_with_behavior_id,spawn_non_sync_object,play_sound,obj_count_objects_with_behavior_id,type,mod_storage_save_number,vec3f_add,find_ceil_height,string_format,djui_chat_message_create,mod_storage_save_bool,error = math.tointeger,mod_storage_load_number,network_is_server,math.random,tonumber,get_skybox,set_override_envfx,network_check_singleplayer_pause,get_network_area_timer,play_transition,obj_get_first_with_behavior_id,spawn_non_sync_object,play_sound,obj_count_objects_with_behavior_id,type,mod_storage_save_number,vec3f_add,find_ceil_height,string.format,djui_chat_message_create,mod_storage_save_bool,error

gGlobalSyncTable.wcEnabled = true
gGlobalSyncTable.weatherType = if_then_else(network_is_server(), math_tointeger(mod_storage_load_number("weather_type")), WEATHER_CLEAR)
gGlobalSyncTable.timeUntilWeatherChange = tonumber(mod_storage_load("time_until_weather_change")) or math_random(WEATHER_MIN_DURATION, WEATHER_MAX_DURATION)

gWeatherState = {
    prevWeatherType = WEATHER_CLEAR,
    transitionTimer = WEATHER_TRANSITION_TIME,
    timeUntilLightning = WEATHER_TRANSITION_TIME,
    flashTimer = 0,
    aurora = mod_storage_load_bool_2("aurora")
}

--- Returns whether or not the game should visually show the weather cycle
function show_weather_cycle()
    local skybox = get_skybox()
    local area = gMarioStates[0].area
    return (skybox ~= -1 and
        skybox ~= BACKGROUND_CUSTOM and
        skybox ~= BACKGROUND_FLAMING_SKY and
        skybox ~= BACKGROUND_GREEN_SKY and
        area ~= nil and area.terrainType ~= TERRAIN_SAND)
        or in_vanilla_level(LEVEL_DDD) or in_vanilla_level(LEVEL_WDW)
end

--- Returns whether or not Weather Cycle is enabled (also factoring in DNC)
function is_wc_enabled()
    return _G.dayNightCycleApi.is_dnc_enabled() and gGlobalSyncTable.wcEnabled and weatherCycleApi.enabled
end

local function update()
    set_override_envfx(ENVFX_MODE_NO_OVERRIDE)

    if not is_wc_enabled() then return end

    if network_is_server() then weather_update() end

    if network_check_singleplayer_pause() then return end

    --- @type NetworkPlayer
    local np = gNetworkPlayers[0]
    --- @type MarioState
    local m = gMarioStates[0]
    if np.currActNum == 99 and np.currLevelNum == LEVEL_CASTLE_GROUNDS and m.action ~= ACT_END_WAVING_CUTSCENE then
        if get_network_area_timer() == 500 then
            gGlobalSyncTable.weatherType = WEATHER_CLEAR
        end

        -- HACK: make the fade from color transition shorter so you can see the storm fade away better
        if m.actionArg == 3 and m.actionTimer == 45 then
            play_transition(WARP_TRANSITION_FADE_FROM_COLOR, 45, 0xFF, 0xFF, 0xFF)
        end
    end

    if gWeatherState.transitionTimer < WEATHER_TRANSITION_TIME then
        gWeatherState.transitionTimer = gWeatherState.transitionTimer + _G.dayNightCycleApi.get_time_scale()
    end

    if not show_weather_cycle() then return end

    -- spawn aurora
    -- despite having the same position and everything, the order
    -- in which the skybox and aurora are spawned will determine
    -- who goes in front of the other, transparency wise...
    -- interesting!
    local skybox = get_skybox()
    if gWeatherState.aurora and weatherCycleApi.aurora and not _G.dayNightCycleApi.is_static_skybox(skybox) and obj_get_first_with_behavior_id(bhvWCAurora) == nil then
        spawn_non_sync_object(
            bhvWCAurora,
            E_MODEL_WC_AURORA,
            0, 0, 0,
            nil
        )
    end

    local prevWeather = get_prev_weather()

    -- spawn weather skybox
    if obj_get_first_with_behavior_id(bhvWCSkybox) == nil then
        spawn_non_sync_object(
            bhvWCSkybox,
            prevWeather.skyboxModel,
            0, 0, 0,
            nil
        )
    end

    local weather = get_weather()
    if weather.updateFunc ~= nil then weather.updateFunc() end
    if not weather.rain then return end

    if gWeatherState.transitionTimer > WEATHER_TRANSITION_TIME * 0.5 or (prevWeather.rain and weather.rain) then
        if skybox == BACKGROUND_SNOW_MOUNTAINS then
            set_override_envfx(ENVFX_SNOW_BLIZZARD)
            return
        end

        local soundPos = gMarioStates[0].marioObj.header.gfx.cameraToObject
        soundPos.y = soundPos.y + 100
        play_sound(SOUND_ENV_WATERFALL1, soundPos)
    end

    if skybox == BACKGROUND_SNOW_MOUNTAINS then return end

    while obj_count_objects_with_behavior_id(bhvWCRainDroplet) < get_rain_droplet_count() do
        spawn_non_sync_object(
            bhvWCRainDroplet,
            E_MODEL_WC_RAIN_DROPLET,
            0, 0, 0,
            nil
        )
    end
end

local function on_level_init()
    if not is_wc_enabled() then return end

    local level = gNetworkPlayers[0].currLevelNum
    if gNetworkPlayers[0].currActNum ~= 99 then
        if in_vanilla_level(LEVEL_BITS) then
            gGlobalSyncTable.weatherType = WEATHER_RAIN
            gGlobalSyncTable.timeUntilWeatherChange = -1
        elseif in_vanilla_level(LEVEL_BOWSER_3) then
            gGlobalSyncTable.weatherType = WEATHER_STORM
            gGlobalSyncTable.timeUntilWeatherChange = -1
            gWeatherState.timeUntilLightning = 150
        elseif gGlobalSyncTable.timeUntilWeatherChange == -1 and
               not any_player_in_vanilla_level(LEVEL_BITS) and
               not any_player_in_vanilla_level(LEVEL_BOWSER_3) then
            set_weather_type(WEATHER_CLOUDY)
        end
    elseif level == LEVEL_CASTLE_GROUNDS and gMarioStates[0].action ~= ACT_END_WAVING_CUTSCENE then
        gGlobalSyncTable.weatherType = WEATHER_STORM
        gGlobalSyncTable.timeUntilWeatherChange = 129600
    end
end

local function on_exit()
    if network_is_server() then
        mod_storage_save_number("weather_type", gGlobalSyncTable.weatherType)
        mod_storage_save_number("time_until_weather_change", gGlobalSyncTable.timeUntilWeatherChange)
    end
end

local function on_play_sound(soundBits, pos)
    if not get_weather().rain then return soundBits end

    for i = SOUND_TERRAIN_DEFAULT, SOUND_TERRAIN_ICE do
        local sound = soundBits - (i << 16)
        if sound == SOUND_ACTION_TERRAIN_STEP or sound == SOUND_ACTION_TERRAIN_STEP_TIPTOE then
            -- translate to world space
            local soundPos = gLakituState.pos
            vec3f_add(soundPos, pos)

            -- check if there's any ceiling
            if find_ceil_height(soundPos.x, soundPos.y, soundPos.z) == gLevelValues.cellHeightLimit then
                return SOUND_ACTION_TERRAIN_STEP + (SOUND_TERRAIN_WATER << 16)
            end
        end
    end

    return soundBits
end


--- @param msg string
local function on_set_command(msg)
    for index, weather in pairs(gWeatherTable) do
        if msg:lower() == weather.name:lower() then
            set_weather_type(index)
            djui_chat_message_create(string_format("[Weather Cycle] Setting weather to '%s'", weather.name))
            return
        end
    end
    djui_chat_message_create(string_format("\\#ffa0a0\\[Weather Cycle] Could not set weather to '%s'", msg))
end

local function on_query_command()
    djui_chat_message_create("[Weather Cycle] Current weather: " .. get_weather().name)
    djui_chat_message_create("[Weather Cycle] Time until weather change: " .. if_then_else(gGlobalSyncTable.timeUntilWeatherChange == -1, "Unknown", format_time(gGlobalSyncTable.timeUntilWeatherChange)))
end

--- @param msg string
local function on_weather_command(msg)
    local args = string_split(msg)

    if args[1] == "set" then
        if not network_is_server() then
            djui_chat_message_create("\\#ffa0a0\\[Weather Cycle] You do not have permission to run /weather set")
        else
            on_set_command(args[2] or "")
        end
    elseif args[1] == "query" then
        on_query_command()
    elseif args[1] ~= "" then
        djui_chat_message_create("/weather \\#00ffff\\[set|query]")
    else
        if not network_is_server() then
            djui_chat_message_create("\\#ffa0a0\\[Weather Cycle] You do not have permission to enable or disable Weather Cycle")
        else
            gGlobalSyncTable.wcEnabled = not gGlobalSyncTable.wcEnabled
            djui_chat_message_create("[Weather Cycle] Status: " .. on_or_off(gGlobalSyncTable.wcEnabled))
        end
    end

    return true
end


--- @param oldVal integer
local function on_weather_type_changed(_, oldVal, newVal)
    -- ! I believe this calls for everyone when someone joins, and if so that would be slightly annoying, but it shouldn't cause much trouble.
    gWeatherState.prevWeatherType = oldVal
    --- @type NetworkPlayer
    local np = gNetworkPlayers[0]
    local weather = gWeatherTable[newVal]
    local noTransition = (np.currActNum == 99 and np.currLevelNum == LEVEL_CASTLE_GROUNDS and gMarioStates[0].action ~= ACT_END_WAVING_CUTSCENE and newVal == WEATHER_STORM) or
                         (gWeatherTable[oldVal].rain and weather.rain) or
                         _G.dayNightCycleApi.get_time_scale() == 0.0 or
                         get_network_area_timer() < 30

    gWeatherState.transitionTimer = if_then_else(noTransition, WEATHER_TRANSITION_TIME, 0)

    if noTransition then
        if weather.updateFunc == lightning_update then
            gWeatherState.timeUntilLightning = 0
        elseif gWeatherTable[oldVal].updateFunc == lightning_update then
            gWeatherState.timeUntilLightning = 0
            lightning_update()
        end
    end
end


--- @param value boolean
local function on_set_wc_enabled(_, value)
    if weatherCycleApi.lockWeather then
        play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        djui_chat_message_create("\\#ffa0a0\\[Weather Cycle] The Weather Cycle settings have been locked by another mod.")
        return
    end

    gGlobalSyncTable.wcEnabled = value
end

--- @param value boolean
local function on_set_aurora(_, value)
    if weatherCycleApi.lockWeather then
        play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
        djui_chat_message_create("\\#ffa0a0\\[Weather Cycle] The Weather Cycle settings have been locked by another mod.")
        return
    end

    gWeatherState.aurora = value
    mod_storage_save_bool("aurora", value)
end

local sReadonlyMetatable = {
    __index = function(table, key)
        return rawget(table, key)
    end,

    __newindex = function()
        error("Attempt to update a read-only table", 2)
    end
}

_G.weatherCycleApi = {
    version = WC_VERSION, -- The version of the mod
    enabled = true, -- Whether or not the weather cycle is enabled
    lockWeather = false, -- Whether or not the player should be prevented from changing the weather
    aurora = true, -- Whether or not the Aurora should appear
    weather_register = weather_register,
    weather_add_rain = weather_add_rain,
    weather_add_update_func = weather_add_update_func,
    show_weather_cycle = show_weather_cycle,
    get_weather_type = get_weather_type,
    set_weather_type = set_weather_type,
    get_weather_color = get_weather_color,
    event_lightning = lightning_update,
    constants = {
        WC_VERSION_MAJOR = WC_VERSION_MAJOR,
        WC_VERSION_MINOR = WC_VERSION_MINOR,
        WC_VERSION_PATCH = WC_VERSION_PATCH,
        WC_VERSION       = WC_VERSION,

        E_MODEL_WC_SKYBOX_CLOUDY = E_MODEL_WC_SKYBOX_CLOUDY,
        E_MODEL_WC_SKYBOX_STORM  = E_MODEL_WC_SKYBOX_STORM,
        E_MODEL_WC_RAIN_DROPLET  = E_MODEL_WC_RAIN_DROPLET,
        E_MODEL_WC_LIGHTNING     = E_MODEL_WC_LIGHTNING,
        E_MODEL_WC_AURORA        = E_MODEL_WC_AURORA,

        SKYBOX_SCALE            = SKYBOX_SCALE,
        WEATHER_TRANSITION_TIME = WEATHER_TRANSITION_TIME,
        WEATHER_MIN_DURATION    = WEATHER_MIN_DURATION,
        WEATHER_MAX_DURATION    = WEATHER_MAX_DURATION,

        DIR_BRIGHT = DIR_BRIGHT,

        COLOR_WHITE  = COLOR_WHITE,
        COLOR_AURORA = COLOR_AURORA,

        WEATHER_CLEAR  = WEATHER_CLEAR,
        WEATHER_CLOUDY = WEATHER_CLOUDY,
        WEATHER_RAIN   = WEATHER_RAIN,
        WEATHER_STORM  = WEATHER_STORM
    }
}
setmetatable(_G.weatherCycleApi, sReadonlyMetatable)
setmetatable(_G.weatherCycleApi.constants, sReadonlyMetatable)

_G.dayNightCycleApi.dddCeiling = false

gLevelValues.zoomOutCameraOnPause = false

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_EXIT, on_exit)
hook_event(HOOK_ON_PLAY_SOUND, on_play_sound)

hook_chat_command("weather", "\\#00ffff\\[set|query]\\#dcdcdc\\ - The command handle for Weather Cycle DX", on_weather_command)

hook_on_sync_table_change(gGlobalSyncTable, "weatherType", 0, on_weather_type_changed)

if network_is_server() then
    hook_mod_menu_checkbox("Enable Weather Cycle", gGlobalSyncTable.wcEnabled, on_set_wc_enabled)
end

hook_mod_menu_checkbox("Aurora Borealis", gWeatherState.aurora, on_set_aurora)
hook_mod_menu_button("Query Weather", on_query_command)