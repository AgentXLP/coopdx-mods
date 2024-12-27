-- name: Environment Tint
-- incompatible: light environment-tint
-- description: Environment Tint v1.0.1\nBy \\#ec7731\\AgentX\n\n\\#dcdcdc\\This mod tints your environment lighting based on the skybox. It's a very simple concept and execution, but I think the results look pretty nice.

local TINT_DEFAULT = { tintSky = false, color = { r = 255, g = 255, b = 255 }, lightingDir = { x = 0, y = 0, z = 0 } }
local TINT_TTC     = { tintSky = false, color = { r = 220, g = 255, b = 255 }, lightingDir = { x = 0, y = 1, z = 0 } }

local sTintTable = {
    [BACKGROUND_OCEAN_SKY] =       { color = { r = 255, g = 255, b = 255 }, lightingDir = { x = 0, y = 1,     z = 1    } },
    [BACKGROUND_FLAMING_SKY] =     { color = { r = 255, g = 120, b = 75  }, lightingDir = { x = 0, y = -0.25, z = 1    } },
    [BACKGROUND_UNDERWATER_CITY] = { color = { r = 130, g = 150, b = 255 }, lightingDir = { x = 0, y = 0,     z = -0.5 } },
    [BACKGROUND_BELOW_CLOUDS] =    { color = { r = 255, g = 240, b = 180 }, lightingDir = { x = 0, y = 1,     z = 1    } },
    [BACKGROUND_SNOW_MOUNTAINS] =  { color = { r = 160, g = 220, b = 255 }, lightingDir = { x = 0, y = 1,     z = 0    } },
    [BACKGROUND_DESERT] =          { color = { r = 255, g = 200, b = 120 }, lightingDir = { x = 0, y = 0,     z = 0    } },
    [BACKGROUND_HAUNTED] =         { color = { r = 127, g = 100, b = 180 }, lightingDir = { x = 0, y = -1,    z = 0    } },
    [BACKGROUND_GREEN_SKY] =       { color = { r = 155, g = 200, b = 155 }, lightingDir = { x = 0, y = -1,    z = 0    } },
    [BACKGROUND_ABOVE_CLOUDS] =    { color = { r = 120, g = 170, b = 180 }, lightingDir = { x = 0, y = 1,     z = 0    } },
    [BACKGROUND_PURPLE_SKY] =      { color = { r = 255, g = 120, b = 255 }, lightingDir = { x = 0, y = 0,     z = 0    } }
}

--- @param levelNum LevelNum
--- Returns whether or not the local player is in a vanilla level
local function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

local function update()
    local skybox = get_skybox()
    local tint = sTintTable[skybox]
    if tint == nil then -- this likely means we are in an interior area
        if in_vanilla_level(LEVEL_LLL) then
            tint = sTintTable[BACKGROUND_FLAMING_SKY]
        elseif in_vanilla_level(LEVEL_WDW) then
            tint = sTintTable[BACKGROUND_UNDERWATER_CITY]
        elseif in_vanilla_level(LEVEL_THI) then
            tint = sTintTable[BACKGROUND_OCEAN_SKY]
        elseif in_vanilla_level(LEVEL_TTC) then
            tint = TINT_TTC
        else
            tint = TINT_DEFAULT
        end
    end

    set_lighting_color(0, tint.color.r)
    set_lighting_color(1, tint.color.g)
    set_lighting_color(2, tint.color.b)
    set_vertex_color(0, tint.color.r)
    set_vertex_color(1, tint.color.g)
    set_vertex_color(2, tint.color.b)
    set_fog_color(0, tint.color.r)
    set_fog_color(1, tint.color.g)
    set_fog_color(2, tint.color.b)
    if skybox == BACKGROUND_DESERT then
        set_skybox_color(0, tint.color.r)
        set_skybox_color(1, tint.color.g)
        set_skybox_color(2, tint.color.b)
    else
        set_skybox_color(0, 255)
        set_skybox_color(1, 255)
        set_skybox_color(2, 255)
    end
    set_lighting_dir(0, tint.lightingDir.x)
    set_lighting_dir(1, tint.lightingDir.y)
    set_lighting_dir(2, tint.lightingDir.z)
end

hook_event(HOOK_UPDATE, update)