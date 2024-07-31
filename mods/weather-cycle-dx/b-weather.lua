if _G.dayNightCycleApi == nil or _G.dayNightCycleApi.version == nil then return end

-- localize functions to improve performance
local type,error,get_skybox,clamp,get_network_player_smallest_global,math_random,collision_find_floor,spawn_sync_object = type,error,get_skybox,clamp,get_network_player_smallest_global,math.random,collision_find_floor,spawn_sync_object

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
--- @field public eventFunc function

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
--- @param eventFunc function
--- Registers a type of weather
function weather_register(name, color, opacity, lightingDir, fogIntensity, skyboxModel, skyboxRotSpeed, eventFunc)
    if type(name) ~= "string" then
        error("weather_register: Parameter 'name' must be a string")
        return
    end
    if type(color) ~= "table" then
        error("weather_register: Parameter 'color' must be a Color")
        return
    end
    if not isinteger(opacity) then
        error("weather_register: Parameter 'opacity' must be an integer")
        return
    end
    if type(lightingDir) ~= "number" then
        error("weather_register: Parameter 'lightingDir' must be a number")
        return
    end
    if type(fogIntensity) ~= "number" then
        error("weather_register: Parameter 'fogIntensity' must be a number")
        return
    end
    if not isinteger(skyboxModel) then
        error("weather_register: Parameter 'skyboxModel' must be an ModelExtendedId")
        return
    end
    if type(skyboxRotSpeed) ~= "number" then
        error("weather_register: Parameter 'skyboxRotSpeed' must be a number")
        return
    end
    if type(eventFunc) ~= "function" and eventFunc ~= nil then
        error("weather_register: Parameter 'eventFunc' must be a function")
        return
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
        rain = false,
        rainAmount = 0,
        rainScaleY = 0.0,
        rainSpeed = 0.0,
        eventFunc = eventFunc
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

--- @param weather Weather
--- Gets the color of the weather, accounts for blue tinting in snow levels
function get_weather_color(weather)
    if type(weather) ~= "table" then
        error("get_weather_color: Parameter 'weather' must be a Weather (" .. weather .. ")")
        return
    end

    if get_skybox() == BACKGROUND_SNOW_MOUNTAINS then
        return { r = clamp(weather.color.r * 1.2, 0, 255), g = clamp(weather.color.g * 1.5, 0, 255), b = clamp(weather.color.b * 1.8, 0, 255) }
    end

    return weather.color
end

--- Spawns lightning
function event_lightning()
    if get_network_player_smallest_global().localIndex ~= 0 or get_skybox() == BACKGROUND_SNOW_MOUNTAINS then return end

    if gWeatherState.timeUntilLightning > 0 then
        gWeatherState.timeUntilLightning = gWeatherState.timeUntilLightning - _G.dayNightCycleApi.get_time_scale()
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
    gWeatherState.timeUntilLightning = math_random(SECOND * 5, SECOND * 20)
    gWeatherState.flashTimer = 10
end

WEATHER_CLEAR = weather_register(
    "Clear", -- name
    { r = 255, g = 255, b = 255 }, -- color
    0, -- skybox opacity
    1.0, -- lighting dir
    1.0, -- fog intensity
    E_MODEL_NONE, -- skybox model
    1, -- skybox rotation speed
    nil -- event function
)

WEATHER_CLOUDY = weather_register(
    "Cloudy", -- name
    { r = 220, g = 220, b = 220 }, -- color
    230, -- skybox opacity
    0.9, -- lighting dir
    1.01, -- fog intensity
    E_MODEL_WC_SKYBOX_CLOUDY, -- skybox model
    1, -- skybox rotation speed
    nil -- event function
)

WEATHER_RAIN = weather_register(
    "Rain", -- name
    { r = 150, g = 150, b = 150 }, -- color
    240, -- skybox opacity
    0.9, -- lighting dir
    1.01, -- fog intensity
    E_MODEL_WC_SKYBOX_CLOUDY, -- skybox model
    6, -- skybox rotation speed
    nil -- event function
)
weather_add_rain(WEATHER_RAIN, 40, 0.5, 40)

WEATHER_STORM = weather_register(
    "Storm", -- name
    { r = 100, g = 90, b = 130 }, -- color
    255, -- opacity
    0.8, -- lighting dir
    1.02, -- fog intensity
    E_MODEL_WC_SKYBOX_STORM, -- skybox model
    12, -- skybox rotation speed
    event_lightning -- event function
)
weather_add_rain(WEATHER_STORM, 60, 1.0, 80)