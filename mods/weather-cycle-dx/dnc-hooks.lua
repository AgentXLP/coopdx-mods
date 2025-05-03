if not check_dnc_compatible() then return end

-- localize functions to improve performance
local math_random,obj_get_first_with_behavior_id,vec3f_mul,clamp = math.random,obj_get_first_with_behavior_id,vec3f_mul,clamp

--- @param color Color
local function dnc_set_lighting_color(color)
    if not gGlobalSyncTable.wcEnabled or not show_weather_cycle() then
        -- reset clientside variables
        if gWeatherState.flashTimer ~= 0 then
            gWeatherState.timeUntilLightning = math_random(SECOND * 5, SECOND * 20)
            gWeatherState.flashTimer = 0
        end
        return color
    end

    if gWeatherState.flashTimer > 0 then
        gWeatherState.flashTimer = gWeatherState.flashTimer - 1
        return COLOR_WHITE
    end

    local prevWeather = get_prev_weather()
    local weather = get_weather()
    local lightingColor = color_lerp(get_weather_color(prevWeather), get_weather_color(weather), gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
    return color_mul(color, lightingColor)
end

--- @param ambientColor Color
local function dnc_set_ambient_lighting_color(ambientColor)
    if not gGlobalSyncTable.wcEnabled or not show_weather_cycle() then
        return ambientColor
    end

    local aurora = obj_get_first_with_behavior_id(bhvWCAurora)
    if aurora ~= nil then
        ambientColor = color_lerp(ambientColor, COLOR_AURORA, aurora.oOpacity / 255)
    end

    if gWeatherState.flashTimer > 0 then
        return COLOR_WHITE
    end

    local prevWeather = get_prev_weather()
    local weather = get_weather()
    local lightingColor = color_lerp(get_weather_color(prevWeather), get_weather_color(weather), gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
    return color_mul(ambientColor, lightingColor)
end

--- @param dir number
local function dnc_set_lighting_dir(dir)
    if not gGlobalSyncTable.wcEnabled or not show_weather_cycle() then return dir end

    if gWeatherState.flashTimer > 0 then
        return { x = 0, y = DIR_BRIGHT, z = DIR_BRIGHT }
    end

    local prevWeather = get_prev_weather()
    local weather = get_weather()
    local lightingDir = lerp(prevWeather.lightingDir, weather.lightingDir, gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
    return vec3f_mul(dir, lightingDir)
end

--- @param intensity number
local function dnc_set_fog_intensity(intensity)
    if not gGlobalSyncTable.wcEnabled or not show_weather_cycle() then return intensity end

    local prevWeather = get_prev_weather()
    local weather = get_weather()
    local fogIntensity = lerp(prevWeather.fogIntensity, weather.fogIntensity, gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
    return (intensity + fogIntensity) * 0.5
end

--- @param pos Vec2f
local function dnc_set_display_time_pos(pos)
    if not gGlobalSyncTable.wcEnabled or gWeatherState.flashTimer <= 0 then return nil end

    pos.x = pos.x + random_nonzero(-3, 3)
    pos.y = pos.y + random_nonzero(-3, 3)

    return pos
end

--- @param shouldDelete boolean
local function dnc_delete_at_dark(shouldDelete)
    if get_weather().rain then return true end
    return shouldDelete
end

--- @param oldTime number
--- @param newTime number
--- QOL functionality
local function dnc_set_time(oldTime, newTime)
    local diff = newTime - oldTime
    if diff <= 0 then return end

    gGlobalSyncTable.timeUntilWeatherChange = gGlobalSyncTable.timeUntilWeatherChange - diff

    if gWeatherState.transitionTimer < WEATHER_TRANSITION_TIME then
        gWeatherState.transitionTimer = clamp(gWeatherState.transitionTimer + diff, 0, WEATHER_TRANSITION_TIME)
    end
end

local function dnc_sun_times_changed()
    HOUR_SUNRISE_START = _G.dayNightCycleApi.constants.HOUR_SUNRISE_START
    HOUR_SUNRISE_END = _G.dayNightCycleApi.constants.HOUR_SUNRISE_END

    HOUR_SUNSET_END = _G.dayNightCycleApi.constants.HOUR_SUNSET_END

    HOUR_NIGHT_START = _G.dayNightCycleApi.constants.HOUR_NIGHT_START
end

_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_LIGHTING_COLOR, dnc_set_lighting_color)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_AMBIENT_LIGHTING_COLOR, dnc_set_ambient_lighting_color)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_LIGHTING_DIR, dnc_set_lighting_dir)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_FOG_COLOR, dnc_set_lighting_color)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_FOG_INTENSITY, dnc_set_fog_intensity)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_DISPLAY_TIME_POS, dnc_set_display_time_pos)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_DELETE_AT_DARK, dnc_delete_at_dark)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_TIME, dnc_set_time)
_G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SUN_TIMES_CHANGED, dnc_sun_times_changed)