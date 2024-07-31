-- name: Weather Cycle DX
-- incompatible: weather weather-cycle
-- description: Weather Cycle DX\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a weather cycle system with cloudy skies, rain, and storms to sm64coopdx. It uses Day Night Cycle DX as a base library, meaning you need\nto have the mod enabled in order to use this one. There is also a toggleable\nAurora Borealis that starts after midnight.\n\nSpecial thanks to Floralys for the original concept.\nSpecial thanks to \\#344ee1\\eros71\\#dcdcdc\\ for saving the mod!

if _G.dayNightCycleApi == nil or _G.dayNightCycleApi.version == nil then return end

-- localize functions to improve performance
local get_skybox,network_is_server,error,mod_storage_save_number,math_random,network_check_singleplayer_pause,type,set_override_envfx,get_network_area_timer,play_transition,obj_get_first_with_behavior_id,spawn_non_sync_object,play_sound,obj_count_objects_with_behavior_id,djui_chat_message_create,string_format,mod_storage_save_bool = get_skybox,network_is_server,error,mod_storage_save_number,math.random,network_check_singleplayer_pause,type,set_override_envfx,get_network_area_timer,play_transition,obj_get_first_with_behavior_id,spawn_non_sync_object,play_sound,obj_count_objects_with_behavior_id,djui_chat_message_create,string.format,mod_storage_save_bool

gGlobalSyncTable.wcEnabled = true
gGlobalSyncTable.weatherType = mod_storage_load_number("weather_type")
gGlobalSyncTable.timeUntilWeatherChange = tonumber(mod_storage_load("time_until_weather_change")) or math_random(WEATHER_MIN_DURATION, WEATHER_MAX_DURATION)

gWeatherState = {
    prevWeatherType = WEATHER_CLEAR,
    transitionTimer = WEATHER_TRANSITION_TIME,
    timeUntilLightning = WEATHER_TRANSITION_TIME,
    flashTimer = 0,
    aurora = if_then_else(mod_storage_load("aurora") == nil, true, mod_storage_load_bool("aurora"))
}

--- Returns whether or not the game should visually show the weather cycle
function show_weather_cycle()
    local skybox = get_skybox()
    local area = gMarioStates[0].area
    return (skybox ~= -1 and
        skybox ~= BACKGROUND_CUSTOM and
        skybox ~= BACKGROUND_FLAMING_SKY and
        skybox ~= BACKGROUND_GREEN_SKY and
        skybox ~= BACKGROUND_PURPLE_SKY and
        area ~= nil and area.terrainType ~= TERRAIN_SAND)
        or in_vanilla_level(LEVEL_DDD) or in_vanilla_level(LEVEL_WDW)
end

--- Returns whether or not Weather Cycle is enabled (also factoring in DNC)
function is_weather_cycle_enabled()
    return gGlobalSyncTable.wcEnabled and _G.dayNightCycleApi.enabled
end


--- @param weatherType integer
--- Sets the weather type
local function set_weather_type(weatherType)
    if not network_is_server() then
        error("set_weather_type: This function can only be run by the server")
        return
    end
    if not isinteger(weatherType) then
        error("set_weather_type: Parameter 'weatherType' must be an integer")
        return
    end

    gGlobalSyncTable.weatherType = weatherType
    mod_storage_save_number("weather_type", weatherType)
    gGlobalSyncTable.timeUntilWeatherChange = math_random(WEATHER_MIN_DURATION, WEATHER_MAX_DURATION)
    mod_storage_save_number("time_until_weather_change", gGlobalSyncTable.timeUntilWeatherChange)
end

local function weather_update()
    if network_check_singleplayer_pause() then return end

    if gGlobalSyncTable.timeUntilWeatherChange <= 0 then
        local weatherType = math_random(WEATHER_CLEAR, weatherTypeCount - 1)
        while gGlobalSyncTable.weatherType == weatherType do
            weatherType = math_random(WEATHER_CLEAR, weatherTypeCount - 1)
        end

        set_weather_type(weatherType)
    end

    gGlobalSyncTable.timeUntilWeatherChange = gGlobalSyncTable.timeUntilWeatherChange - _G.dayNightCycleApi.get_time_scale()
end

local function update()
    if not is_weather_cycle_enabled() then
        set_override_envfx(ENVFX_MODE_NO_OVERRIDE)
        return
    end

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

    if not show_weather_cycle() or get_skybox() == -1 then
        set_override_envfx(ENVFX_MODE_NO_OVERRIDE)
        return
    end

    -- spawn aurora
    -- despite having the same position and everything, the order
    -- in which the skybox and aurora are spawned will determine
    -- who goes in front of the other, transparency wise...
    -- interesting!
    if gWeatherState.aurora and get_skybox() ~= BACKGROUND_HAUNTED and obj_get_first_with_behavior_id(bhvWCAurora) == nil then
        spawn_non_sync_object(
            bhvWCAurora,
            E_MODEL_WC_AURORA,
            0, 0, 0,
            nil
        )
    end

    local prevWeather = gWeatherTable[gWeatherState.prevWeatherType]

    -- spawn weather skybox
    if obj_get_first_with_behavior_id(bhvWCSkybox) == nil then
        spawn_non_sync_object(
            bhvWCSkybox,
            prevWeather.skyboxModel,
            0, 0, 0,
            nil
        )
    end

    local weather = gWeatherTable[gGlobalSyncTable.weatherType]
    if weather.eventFunc ~= nil then weather.eventFunc() end
    if not weather.rain then
        set_override_envfx(ENVFX_MODE_NO_OVERRIDE)
        return
    end

    local skybox = get_skybox()

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
    if not is_weather_cycle_enabled() then return end

    if gNetworkPlayers[0].currActNum ~= 99 then return end

    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS and gMarioStates[0].action ~= ACT_END_WAVING_CUTSCENE then
        gGlobalSyncTable.weatherType = WEATHER_STORM
        gGlobalSyncTable.timeUntilWeatherChange = 43200
    end
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
    djui_chat_message_create("[Weather Cycle] Current weather: " .. gWeatherTable[gGlobalSyncTable.weatherType].name)
    djui_chat_message_create("[Weather Cycle] Time until weather change: " .. format_time(gGlobalSyncTable.timeUntilWeatherChange))
end

--- @param msg string
local function on_weather_command(msg)
    local args = split(msg)

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
                         (gWeatherTable[oldVal].rain and weather.rain)
    print(noTransition)

    gWeatherState.transitionTimer = if_then_else(noTransition, WEATHER_TRANSITION_TIME, 0)

    if noTransition and weather.eventFunc == event_lightning then
        gWeatherState.timeUntilLightning = 0
    end
end


--- @param value boolean
local function on_set_wc_enabled(_, value)
    gGlobalSyncTable.wcEnabled = value
end

--- @param value boolean
local function on_set_aurora(_, value)
    gWeatherState.aurora = value
    mod_storage_save_bool("aurora", value)
end

local sReadonlyMetatable = {
    __index = function(table, key)
        return rawget(table, key)
    end,

    __newindex = function()
        error("attempt to update a read-only table", 2)
    end
}

_G.weatherCycleApi = {
    version = WC_VERSION,
    weather_register = weather_register,
    weather_add_rain = weather_add_rain,
    show_weather_cycle = show_weather_cycle,
    set_weather_type = set_weather_type,
    get_weather_color = get_weather_color,
    event_lightning = event_lightning,
    constants = {
        SKYBOX_SCALE = SKYBOX_SCALE,
        WEATHER_TRANSITION_TIME = WEATHER_TRANSITION_TIME,

        COLOR_AURORA = COLOR_AURORA
    }
}
setmetatable(_G.weatherCycleApi, sReadonlyMetatable)

gLevelValues.zoomOutCameraOnPause = false

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)

hook_chat_command("weather", "\\#00ffff\\[set|query]\\#dcdcdc\\ - The command handle for Weather Cycle DX", on_weather_command)

hook_on_sync_table_change(gGlobalSyncTable, "weatherType", 0, on_weather_type_changed)

if network_is_server() then
    hook_mod_menu_checkbox("Enable Weather Cycle", gGlobalSyncTable.wcEnabled, on_set_wc_enabled)
end

hook_mod_menu_checkbox("Aurora Borealis", gWeatherState.aurora, on_set_aurora)