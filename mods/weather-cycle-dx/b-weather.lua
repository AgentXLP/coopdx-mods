if not check_dnc_compatible() then return end

-- localize functions to improve performance
local type,error,get_skybox,math_clamp,math_random,network_check_singleplayer_pause,math_max,get_network_player_smallest_global,collision_find_floor,spawn_sync_object = type,error,get_skybox,math.clamp,math.random,network_check_singleplayer_pause,math.max,get_network_player_smallest_global,collision_find_floor,spawn_sync_object

--- @class Weather
--- @field public name string
--- @field public color Color
--- @field public opacity integer
--- @field public lightingDir number
--- @field public fogIntensity number
--- @field public skyboxModel ModelExtendedId
--- @field public skyboxRotSpeed number
--- @field public rain boolean
--- @field public rainAmount integer
--- @field public rainScaleY number
--- @field public rainSpeed number
--- @field public updateFunc function

weatherTypeCount = 0

--- @type Weather[]
gWeatherTable = {}

--- @param name string
--- @param color Color
--- @param opacity integer
--- @param lightingDir number
--- @param fogIntensity number
--- @param skyboxModel ModelExtendedId
--- @param skyboxRotSpeed number
--- @return integer
--- Registers a type of weather
function weather_register(name, color, opacity, lightingDir, fogIntensity, skyboxModel, skyboxRotSpeed)
    if type(name) ~= "string" then
        error("weather_register: Parameter 'name' must be a string")
        return 0
    end
    if type(color) ~= "table" then
        error("weather_register: Parameter 'color' must be a Color")
        return 0
    end
    if not isinteger(opacity) then
        error("weather_register: Parameter 'opacity' must be an integer")
        return 0
    end
    if type(lightingDir) ~= "number" then
        error("weather_register: Parameter 'lightingDir' must be a number")
        return 0
    end
    if type(fogIntensity) ~= "number" then
        error("weather_register: Parameter 'fogIntensity' must be a number")
        return 0
    end
    if not isinteger(skyboxModel) then
        error("weather_register: Parameter 'skyboxModel' must be an ModelExtendedId")
        return 0
    end
    if type(skyboxRotSpeed) ~= "number" then
        error("weather_register: Parameter 'skyboxRotSpeed' must be a number")
        return 0
    end

    weatherTypeCount = weatherTypeCount + 1
    local weatherTypeIndex = weatherTypeCount - 1
    gWeatherTable[weatherTypeIndex] = {
        name = name,
        color = color,
        opacity = opacity,
        lightingDir = lightingDir,
        fogIntensity = fogIntensity,
        skyboxModel = skyboxModel,
        skyboxRotSpeed = skyboxRotSpeed,
        updateFunc = nil,
        rain = false,
        rainAmount = 0,
        rainScaleY = 0.0,
        rainSpeed = 0.0
    }
    return weatherTypeIndex
end

--- @param weatherType integer
--- @param amount integer
--- @param scaleY number
--- @param speed number
--- Adds rain to a registered weather type
function weather_add_rain(weatherType, amount, scaleY, speed)
    if gWeatherTable[weatherType] == nil then
        error("weather_add_rain: Weather type '" .. weatherType .. "' does not exist!")
        return
    end
    if not isinteger(amount) then
        error("weather_add_rain: Parameter 'amount' must be an integer")
        return
    end
    if type(scaleY) ~= "number" then
        error("weather_add_rain: Parameter 'scaleY' must be a number")
        return
    end
    if type(speed) ~= "number" then
        error("weather_add_rain: Parameter 'speed' must be a number")
        return
    end

    local weather = gWeatherTable[weatherType]
    weather.rain = true
    weather.rainAmount = amount
    weather.rainScaleY = scaleY
    weather.rainSpeed = speed
end

--- @param weatherType integer
--- @param updateFunc function
--- Adds an update function to the weather
function weather_add_update_func(weatherType, updateFunc)
    if gWeatherTable[weatherType] == nil then
        error("weather_add_rain: Weather type '" .. weatherType .. "' does not exist!")
        return
    end
    if type(updateFunc) ~= "function" then
        error("weather_add_update_func: Parameter 'updateFunc' must be a function")
        return
    end

    local weather = gWeatherTable[weatherType]
    weather.updateFunc = updateFunc
end

--- @param weather Weather
--- Gets the color of the weather, accounts for tinting with some skyboxes
function get_weather_color(weather)
    if type(weather) ~= "table" then
        error("get_weather_color: Parameter 'weather' must be a Weather (" .. weather .. ")")
        return nil
    end
    if weather == gWeatherTable[WEATHER_CLEAR] then return weather.color end

    local skybox = get_skybox()
    if skybox == BACKGROUND_UNDERWATER_CITY then
        return { r = weather.color.r * 0.6, g = weather.color.g * 0.65, b = weather.color.b * 0.9 }
    elseif skybox == BACKGROUND_SNOW_MOUNTAINS then
        return { r = math_clamp(weather.color.r * 1.1, 0, 255), g = math_clamp(weather.color.g * 1.4, 0, 255), b = math_clamp(weather.color.b * 1.7, 0, 255) }
    elseif skybox == BACKGROUND_HAUNTED then
        return { r = weather.color.r * 0.6, g = weather.color.g * 0.6, b = weather.color.b }
    elseif skybox == BACKGROUND_PURPLE_SKY then
        return { r = math_clamp(weather.color.r * 1.75, 0, 255), g = math_clamp(weather.color.r * 1, 0, 255), b = math_clamp(weather.color.b * 2.0, 0, 255) }
    end

    return weather.color
end

--- Gets the weather type
--- @return integer
function get_weather_type()
    return gGlobalSyncTable.weatherType
end

--- @return Weather
--- Gets the current weather
function get_weather()
    return gWeatherTable[gGlobalSyncTable.weatherType]
end

--- @return Weather
--- Gets the previous weather
function get_prev_weather()
    return gWeatherTable[gWeatherState.prevWeatherType]
end

--- @param weatherType integer
--- Sets the weather type
function set_weather_type(weatherType)
    if not isinteger(weatherType) then
        error("set_weather_type: Parameter 'weatherType' must be an integer")
        return
    end

    gGlobalSyncTable.weatherType = weatherType
    gGlobalSyncTable.timeUntilWeatherChange = math_random(WEATHER_MIN_DURATION, WEATHER_MAX_DURATION)
end

function weather_update()
    if network_check_singleplayer_pause() then return end

    local timeScale = _G.dayNightCycleApi.get_time_scale()
    if timeScale == 0.0 then return end

    if gGlobalSyncTable.timeUntilWeatherChange == 0 then
        local weatherType = math_random(WEATHER_CLEAR, weatherTypeCount - 1)
        while gGlobalSyncTable.weatherType == weatherType do
            weatherType = math_random(WEATHER_CLEAR, weatherTypeCount - 1)
        end

        set_weather_type(weatherType)
    elseif gGlobalSyncTable.timeUntilWeatherChange ~= -1 then
        gGlobalSyncTable.timeUntilWeatherChange = math_max(gGlobalSyncTable.timeUntilWeatherChange - timeScale, 0)
    end
end

--- Spawns lightning
function lightning_update()
    if get_network_player_smallest_global().localIndex ~= 0 or get_skybox() == BACKGROUND_SNOW_MOUNTAINS then return end

    if gWeatherState.timeUntilLightning > 0 then
        gWeatherState.timeUntilLightning = gWeatherState.timeUntilLightning - 1
        return
    end

    local pos = { x = math_random(-10000, 10000), y = 10000, z = math_random(-10000, 10000) }
    if in_vanilla_level(LEVEL_SA) then
        while collision_find_floor(pos.x, pos.y, pos.z) ~= nil do
            pos = { x = math_random(-10000, 10000), y = 10000, z = math_random(-10000, 10000) }
        end
    else
        while collision_find_floor(pos.x, pos.y, pos.z) == nil do -- ! will freeze on levels with no floor
            pos = { x = math_random(-10000, 10000), y = 10000, z = math_random(-10000, 10000) }
        end
    end

    spawn_sync_object(
        bhvWCLightning,
        E_MODEL_WC_LIGHTNING,
        pos.x, pos.y, pos.z,
        nil
    )
    gWeatherState.timeUntilLightning = math_random(SECOND * 5, SECOND * if_then_else(gNetworkPlayers[0].currLevelNum == LEVEL_BOWSER_3, 10, 20))
    gWeatherState.flashTimer = 15
end


WEATHER_CLEAR = weather_register(
    "Clear", -- name
    { r = 255, g = 255, b = 255 }, -- color
    0, -- skybox opacity
    1.0, -- lighting dir
    1.0, -- fog intensity
    E_MODEL_NONE, -- skybox model
    1 -- skybox rotation speed
)

WEATHER_CLOUDY = weather_register(
    "Cloudy", -- name
    { r = 220, g = 220, b = 220 }, -- color
    230, -- skybox opacity
    0.9, -- lighting dir
    1.01, -- fog intensity
    E_MODEL_WC_SKYBOX_CLOUDY, -- skybox model
    1 -- skybox rotation speed
)

WEATHER_RAIN = weather_register(
    "Rain", -- name
    { r = 170, g = 170, b = 180 }, -- color
    240, -- skybox opacity
    0.9, -- lighting dir
    1.01, -- fog intensity
    E_MODEL_WC_SKYBOX_CLOUDY, -- skybox model
    6 -- skybox rotation speed
)
weather_add_rain(WEATHER_RAIN, 50, 0.6, 50)

WEATHER_STORM = weather_register(
    "Storm", -- name
    { r = 100, g = 90, b = 140 }, -- color
    255, -- opacity
    0.8, -- lighting dir
    1.02, -- fog intensity
    E_MODEL_WC_SKYBOX_STORM, -- skybox model
    12 -- skybox rotation speed
)
weather_add_rain(WEATHER_STORM, 60, 1.5, 80)
weather_add_update_func(WEATHER_STORM, lightning_update)