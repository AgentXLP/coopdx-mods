-- name: Environment Tint
-- incompatible: light environment-tint
-- description: Environment Tint v1.1\nBy \\#ec7731\\AgentX\n\n\\#dcdcdc\\This mod tints your environment lighting based on the skybox, level, or region. It's a simple concept, but I think the results speak for themselves. Enjoy!

local TINT_DEFAULT = { color = { r = 255, g = 255, b = 255 }, lightingDir = { x = 0, y = 0, z = 0 } }
local TINT_CASTLE  = { color = { r = 180, g = 220, b = 255 }, lightingDir = { x = 0, y = 0, z = 1 } }
local TINT_TTC     = { color = { r = 200, g = 255, b = 255 }, lightingDir = { x = 0, y = 1, z = 0 } }

local sTintTable = {
    [BACKGROUND_OCEAN_SKY] =       { color = { r = 220, g = 255, b = 200 }, lightingDir = { x = 0, y = 1,     z = 1    } },
    [BACKGROUND_FLAMING_SKY] =     { color = { r = 255, g = 110, b = 50  }, lightingDir = { x = 0, y = -0.25, z = 1    } },
    [BACKGROUND_UNDERWATER_CITY] = { color = { r = 130, g = 150, b = 255 }, lightingDir = { x = 0, y = 0,     z = -0.5 } },
    [BACKGROUND_BELOW_CLOUDS] =    { color = { r = 255, g = 240, b = 150 }, lightingDir = { x = 0, y = 1,     z = 1    } },
    [BACKGROUND_SNOW_MOUNTAINS] =  { color = { r = 160, g = 220, b = 255 }, lightingDir = { x = 0, y = 1,     z = 0    } },
    [BACKGROUND_DESERT] =          { color = { r = 255, g = 200, b = 120 }, lightingDir = { x = 0, y = 0,     z = 0    } },
    [BACKGROUND_HAUNTED] =         { color = { r = 130, g = 100, b = 200 }, lightingDir = { x = 0, y = -1,    z = 0    } },
    [BACKGROUND_GREEN_SKY] =       { color = { r = 140, g = 200, b = 140 }, lightingDir = { x = 0, y = -1,    z = 0    } },
    [BACKGROUND_ABOVE_CLOUDS] =    { color = { r = 120, g = 180, b = 200 }, lightingDir = { x = 0, y = 1,     z = 0    } },
    [BACKGROUND_PURPLE_SKY] =      { color = { r = 255, g = 120, b = 255 }, lightingDir = { x = 0, y = 0,     z = 0    } }
}

--- @param levelNum LevelNum
--- Returns whether or not the local player is in a vanilla level
local function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

--- @param color Color
--- @param tintSkybox boolean
--- @param lightingDir Vec3f
local function set_world_properties(color, tintSkybox, lightingDir)
    set_lighting_color(0, color.r)
    set_lighting_color(1, color.g)
    set_lighting_color(2, color.b)
    set_vertex_color(0, color.r)
    set_vertex_color(1, color.g)
    set_vertex_color(2, color.b)
    set_fog_color(0, color.r)
    set_fog_color(1, color.g)
    set_fog_color(2, color.b)
    if tintSkybox then
        set_skybox_color(0, color.r)
        set_skybox_color(1, color.g)
        set_skybox_color(2, color.b)
    else
        set_skybox_color(0, 255)
        set_skybox_color(1, 255)
        set_skybox_color(2, 255)
    end
    set_lighting_dir(0, lightingDir.x)
    set_lighting_dir(1, lightingDir.y)
    set_lighting_dir(2, lightingDir.z)
end

local function update()
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
        else
            tint = TINT_DEFAULT
        end
    end

    set_world_properties(tint.color, skybox == BACKGROUND_DESERT, tint.lightingDir)
end

local function on_hud_render_behind()
    --- @type MarioState
    local m = gMarioStates[0]
    if gLakituState.pos.y < m.waterLevel then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        if in_vanilla_level(LEVEL_JRB) then
            djui_hud_set_color(0, 100, 130, 100)
        elseif in_vanilla_level(LEVEL_LLL) then
            djui_hud_set_color(255, 20, 0, 175)
        else
            djui_hud_set_color(0, 50, 230, 100)
        end
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    elseif gLakituState.pos.y < find_poison_gas_level(m.pos.x, m.pos.z) then
        djui_hud_set_resolution(RESOLUTION_DJUI)

        djui_hud_set_color(150, 200, 0, 100)
        djui_hud_render_rect(0, 0, djui_hud_get_screen_width(), djui_hud_get_screen_height())
    end
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_HUD_RENDER_BEHIND, on_hud_render_behind)