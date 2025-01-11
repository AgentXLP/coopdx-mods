-- localize functions to improve performance
local play_sound,djui_chat_message_create,math_tointeger,string_format,smlua_model_util_get_id = play_sound,djui_chat_message_create,math.tointeger,string.format,smlua_model_util_get_id

--- Checks if DNC is enabled and the version is high enough
function check_dnc_compatible()
    return _G.dayNightCycleApi ~= nil and _G.dayNightCycleApi.version ~= nil and _G.dayNightCycleApi.version >= 230
end

if not check_dnc_compatible() then
    local first = false
    hook_event(HOOK_ON_LEVEL_INIT, function()
        if not first then
            first = true
            play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
            djui_chat_message_create("\\#ffa0a0\\Weather Cycle DX requires Day Night Cycle v2.3 or higher to be enabled. Please rehost with it enabled.")
        end
    end)
    return
end

WC_VERSION_MAJOR = 1
WC_VERSION_MINOR = 1
WC_VERSION_PATCH = 1
WC_VERSION = math_tointeger(string_format("%d%d%d", WC_VERSION_MAJOR, WC_VERSION_MINOR, WC_VERSION_PATCH))

-- skybox constants
E_MODEL_WC_SKYBOX_CLOUDY = smlua_model_util_get_id("wc_skybox_cloudy_geo")
E_MODEL_WC_SKYBOX_STORM = smlua_model_util_get_id("wc_skybox_storm_geo")
E_MODEL_WC_RAIN_DROPLET = smlua_model_util_get_id("wc_rain_droplet_geo")
E_MODEL_WC_LIGHTNING = smlua_model_util_get_id("wc_lightning_geo")
E_MODEL_WC_AURORA = smlua_model_util_get_id("wc_aurora_geo")

SKYBOX_SCALE = _G.dayNightCycleApi.constants.SKYBOX_SCALE - 30

-- time constants
SECOND = _G.dayNightCycleApi.constants.SECOND
MINUTE = _G.dayNightCycleApi.constants.MINUTE

HOUR_SUNRISE_START = _G.dayNightCycleApi.constants.HOUR_SUNRISE_START
HOUR_SUNRISE_END = _G.dayNightCycleApi.constants.HOUR_SUNRISE_END
HOUR_SUNRISE_DURATION = _G.dayNightCycleApi.constants.HOUR_SUNRISE_DURATION

HOUR_SUNSET_END = _G.dayNightCycleApi.constants.HOUR_SUNSET_END
HOUR_SUNSET_DURATION = _G.dayNightCycleApi.constants.HOUR_SUNSET_DURATION

HOUR_NIGHT_START = _G.dayNightCycleApi.constants.HOUR_NIGHT_START

WEATHER_TRANSITION_TIME = SECOND * 10
WEATHER_MIN_DURATION = MINUTE * 3
WEATHER_MAX_DURATION = MINUTE * 10

-- lighting direction constants
DIR_BRIGHT = _G.dayNightCycleApi.constants.DIR_BRIGHT

-- colors
COLOR_WHITE = { r = 255, g = 255, b = 255 }
COLOR_AURORA = { r = 100, g = 150, b = 100 }