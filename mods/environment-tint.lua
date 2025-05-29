-- name: Environment Tint
-- incompatible: environment-tint
-- description: Environment Tint v1.3.1\nBy \\#ec7731\\AgentX\n\n\\#dcdcdc\\This mod tints your environment lighting based on the skybox, level, or region. It's a simple concept, but I think the results speak for themselves. Enjoy!

-- localize functions to improve performance
local math_lerp,math_round,level_is_vanilla_level,set_lighting_color,set_vertex_color,set_fog_color,set_lighting_dir,get_skybox,math_clamp,djui_hud_set_resolution,get_lighting_color,djui_hud_set_color,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_render_rect,find_poison_gas_level = math.lerp,math.round,level_is_vanilla_level,set_lighting_color,set_vertex_color,set_fog_color,set_lighting_dir,get_skybox,math.clamp,djui_hud_set_resolution,get_lighting_color,djui_hud_set_color,djui_hud_get_screen_width,djui_hud_get_screen_height,djui_hud_render_rect,find_poison_gas_level

local TINT_DEFAULT = { color = { r = 255, g = 255, b = 255 }, lightingDir = { x = 0, y = 0, z = 0 } }
local TINT_CASTLE  = { color = { r = 180, g = 210, b = 255 }, lightingDir = { x = 0, y = 0, z = 1 } }
local TINT_TTC     = { color = { r = 200, g = 255, b = 255 }, lightingDir = { x = 0, y = 1, z = 0 } }
local TINT_PSS     = { color = { r = 255, g = 180, b = 120 }, lightingDir = { x = 0, y = 1, z = 0 } }

local COLOR_WATER     = { r = 0,   g = 50,  b = 250 }
local COLOR_JRB_WATER = { r = 0,   g = 100, b = 130 }
local COLOR_LAVA      = { r = 255, g = 20,  b = 0   }
local COLOR_POISON    = { r = 150, g = 200, b = 0   }

if _G.dayNightCycleApi ~= nil then
    HOUR_SUNRISE_END      = _G.dayNightCycleApi.constants.HOUR_SUNRISE_END
    HOUR_SUNRISE_DURATION = _G.dayNightCycleApi.constants.HOUR_SUNRISE_DURATION

    HOUR_DAY_START = _G.dayNightCycleApi.constants.HOUR_DAY_START

    HOUR_SUNSET_START      = _G.dayNightCycleApi.constants.HOUR_SUNSET_START
    HOUR_SUNSET_END        = _G.dayNightCycleApi.constants.HOUR_SUNSET_END
    HOUR_SUNSET_DURATION   = _G.dayNightCycleApi.constants.HOUR_SUNSET_DURATION
end

local sTintTable = {
    [BACKGROUND_OCEAN_SKY] =       { color = { r = 200, g = 230, b = 255 }, lightingDir = { x = 0, y = 1,     z = 1     } },
    [BACKGROUND_FLAMING_SKY] =     { color = { r = 255, g = 110, b = 50  }, lightingDir = { x = 0, y = -0.25, z = 0     } },
    [BACKGROUND_UNDERWATER_CITY] = { color = { r = 130, g = 150, b = 255 }, lightingDir = { x = 0, y = 0,     z = -0.25 } },
    [BACKGROUND_BELOW_CLOUDS] =    { color = { r = 210, g = 210, b = 255 }, lightingDir = { x = 0, y = 1,     z = 1     } },
    [BACKGROUND_SNOW_MOUNTAINS] =  { color = { r = 160, g = 220, b = 255 }, lightingDir = { x = 0, y = 1,     z = 0     } },
    [BACKGROUND_DESERT] =          { color = { r = 255, g = 200, b = 120 }, lightingDir = { x = 0, y = 0,     z = 0     } },
    [BACKGROUND_HAUNTED] =         { color = { r = 180, g = 150, b = 255 }, lightingDir = { x = 0, y = -1,    z = 0     } },
    [BACKGROUND_GREEN_SKY] =       { color = { r = 150, g = 210, b = 150 }, lightingDir = { x = 0, y = -0.5,  z = 0     } },
    [BACKGROUND_ABOVE_CLOUDS] =    { color = { r = 120, g = 200, b = 200 }, lightingDir = { x = 0, y = 1,     z = 0     } },
    [BACKGROUND_PURPLE_SKY] =      { color = { r = 255, g = 120, b = 255 }, lightingDir = { x = 0, y = 0,     z = 0     } }
}

--- @param a number
--- @param b number
--- @param t number
--- Linearly interpolates between two points using a delta but rounds the final value
local function lerp_round(a, b, t)
    return math_round(math_lerp(a, b, t))
end

--- @param a Color
--- @param b Color
--- @return Color
--- Linearly interpolates between two colors using a delta
local function color_lerp(a, b, t)
    return {
        r = lerp_round(a.r, b.r, t),
        g = lerp_round(a.g, b.g, t),
        b = lerp_round(a.b, b.b, t)
    }
end

--- @param a Color
--- @param b Color
--- @return Color
--- Multiplies two colors together
local function color_mul(a, b)
    return {
        r = a.r * (b.r / 255.0),
        g = a.g * (b.g / 255.0),
        b = a.b * (b.b / 255.0)
    }
end

--- @param a Vec3f
--- @param b Vec3f
--- @return Vec3f
--- Linearly interpolates between two Vec3fs using a delta
local function vec3f_lerp(a, b, t)
    return {
        x = math_lerp(a.x, b.x, t),
        y = math_lerp(a.y, b.y, t),
        z = math_lerp(a.z, b.z, t)
    }
end

--- @param levelNum LevelNum
--- Returns whether or not the local player is in a vanilla level
local function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

--- @param color Color
--- @param lightingDir Vec3f
--- Sets the properties of the world
local function set_world_properties(color, lightingDir)
    set_lighting_color(0, color.r)
    set_lighting_color(1, color.g)
    set_lighting_color(2, color.b)
    set_vertex_color(0, color.r)
    set_vertex_color(1, color.g)
    set_vertex_color(2, color.b)
    set_fog_color(0, color.r)
    set_fog_color(1, color.g)
    set_fog_color(2, color.b)
    set_lighting_dir(0, lightingDir.x)
    set_lighting_dir(1, lightingDir.y)
    set_lighting_dir(2, lightingDir.z)
end

--- Gets the environment tint in the current level/area
local function get_environment_tint()
    local skybox = get_skybox()
    local tint = sTintTable[skybox]
    if tint == nil then -- we're probably in an interior area
        if in_vanilla_level(LEVEL_CASTLE) then
            tint = TINT_CASTLE
        elseif in_vanilla_level(LEVEL_CCM) then
            tint = sTintTable[BACKGROUND_SNOW_MOUNTAINS]
        elseif in_vanilla_level(LEVEL_LLL) then
            tint = sTintTable[BACKGROUND_FLAMING_SKY]
        elseif in_vanilla_level(LEVEL_HMC) then
            tint = sTintTable[BACKGROUND_GREEN_SKY]
        elseif in_vanilla_level(LEVEL_DDD) or in_vanilla_level(LEVEL_THI) then
            tint = sTintTable[BACKGROUND_OCEAN_SKY]
        elseif in_vanilla_level(LEVEL_WDW) then
            tint = sTintTable[BACKGROUND_UNDERWATER_CITY]
        elseif in_vanilla_level(LEVEL_SSL) then
            tint = sTintTable[BACKGROUND_DESERT]
        elseif in_vanilla_level(LEVEL_TTC) then
            tint = TINT_TTC
        elseif in_vanilla_level(LEVEL_PSS) then
            tint = TINT_PSS
        else
            tint = TINT_DEFAULT
        end
    end

    return tint
end

--- [DNC Only] Gets the level between 0.0 and 1.0 that the environment tint should be at based on the time
local function get_tint_intensity()
    local minutes = _G.dayNightCycleApi.get_time_minutes()

    local t = 0.0
    if minutes >= HOUR_SUNRISE_END and minutes <= HOUR_DAY_START then
        t = math_clamp((minutes - HOUR_SUNRISE_END) / HOUR_SUNRISE_DURATION, 0, 1)
    elseif minutes >= HOUR_SUNSET_START and minutes <= HOUR_SUNSET_END then
        t = 1 - math_clamp((minutes - HOUR_SUNSET_START) / (HOUR_SUNSET_DURATION * 0.5), 0, 1)
    elseif minutes > HOUR_DAY_START and minutes < HOUR_SUNSET_START then
        t = 1.0
    end

    return t
end

--- @param color Color
local function dnc_set_lighting_color(color)
    return color_lerp(color, get_environment_tint().color, get_tint_intensity())
end

--- @param lightingDir Vec3f
local function dnc_set_lighting_dir(lightingDir)
    return vec3f_lerp(lightingDir, get_environment_tint().lightingDir, get_tint_intensity())
end

local function dnc_sun_times_changed()
    HOUR_SUNRISE_END = _G.dayNightCycleApi.constants.HOUR_SUNRISE_END

    HOUR_DAY_START = _G.dayNightCycleApi.constants.HOUR_DAY_START

    HOUR_SUNSET_START = _G.dayNightCycleApi.constants.HOUR_SUNSET_START
    HOUR_SUNSET_END = _G.dayNightCycleApi.constants.HOUR_SUNSET_END
end


local function update()
    local tint = get_environment_tint()
    set_world_properties(tint.color, tint.lightingDir)
end

local function on_hud_render_behind()
    if gNetworkPlayers[0].currActNum == 99 then return end

    --- @type MarioState
    local m = gMarioStates[0]
    if gLakituState.pos.y < m.waterLevel then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        lightingColor = { r = get_lighting_color(0), g = get_lighting_color(1), b = get_lighting_color(2) }
        if in_vanilla_level(LEVEL_JRB) then
            local color = color_mul(COLOR_JRB_WATER, lightingColor)
            djui_hud_set_color(color.r, color.g, color.b, 100)
        elseif in_vanilla_level(LEVEL_LLL) then
            local color = color_mul(COLOR_LAVA, lightingColor)
            djui_hud_set_color(color.r, color.g, color.b, 175)
        else
            local color = color_mul(COLOR_WATER, lightingColor)
            djui_hud_set_color(color.r, color.g, color.b, 100)
        end
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    elseif gLakituState.pos.y < find_poison_gas_level(m.pos.x, m.pos.z) then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        djui_hud_set_color(COLOR_POISON.r, COLOR_POISON.g, COLOR_POISON.b, 100)
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end
end

if _G.dayNightCycleApi ~= nil then
    _G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_LIGHTING_COLOR, dnc_set_lighting_color)
    _G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_AMBIENT_LIGHTING_COLOR, dnc_set_lighting_color)
    _G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SET_LIGHTING_DIR, dnc_set_lighting_dir)
    _G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_SUN_TIMES_CHANGED, dnc_sun_times_changed)
    _G.dayNightCycleApi.dnc_hook_event(_G.dayNightCycleApi.constants.DNC_HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)
else
    hook_event(HOOK_UPDATE, update)
    hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)
end