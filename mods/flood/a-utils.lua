moveset = false
cheats = false

for mod in pairs(gActiveMods) do
    if gActiveMods[mod].name:find("Object Spawner") then
        cheats = true
    end
end

if gServerSettings.enableCheats ~= 0 then
    cheats = true
end

for i in pairs(gActiveMods) do
    if (gActiveMods[i].incompatible ~= nil and gActiveMods[i].incompatible:find("moveset")) or gActiveMods[i].name:find("Squishy's Server") then
        moveset = true
    end
end

-- localize functions to improve performance
local math_floor = math.floor
local math_ceil = math.ceil
local center_rom_hack_camera = center_rom_hack_camera
local set_camera_mode = set_camera_mode
local djui_hud_set_color = djui_hud_set_color
local network_discord_id_from_local_index = network_discord_id_from_local_index
local is_game_paused = is_game_paused

local sOverrideCameraModes = {
    [CAMERA_MODE_RADIAL]            = true,
    [CAMERA_MODE_OUTWARD_RADIAL]    = true,
    [CAMERA_MODE_CLOSE]             = true,
    [CAMERA_MODE_SLIDE_HOOT]        = true,
    [CAMERA_MODE_PARALLEL_TRACKING] = true,
    [CAMERA_MODE_FIXED]             = true,
    [CAMERA_MODE_8_DIRECTIONS]      = true,
    [CAMERA_MODE_FREE_ROAM]         = true,
    [CAMERA_MODE_SPIRAL_STAIRS]     = true,
}

--- @param m MarioState
function romhack_camera(m)
    if sOverrideCameraModes[m.area.camera.mode] == nil then return end

    if (m.controller.buttonPressed & L_TRIG) ~= 0 then center_rom_hack_camera() end

    set_camera_mode(m.area.camera, CAMERA_MODE_ROM_HACK, 0)
end

rom_hack_cam_set_collisions(false)

-- Rounds up or down depending on the decimal position of `x`.
--- @param x number
--- @return integer
function math_round(x)
    return if_then_else(x - math_floor(x) >= 0.5, math_ceil(x), math_floor(x))
end

-- Recieves a value of any type and converts it into a boolean.
function tobool(v)
    local type = type(v)
    if type == "boolean" then
        return v
    elseif type == "number" then
        return v == 1
    elseif type == "string" then
        return v == "true"
    elseif type == "table" or type == "function" or type == "thread" or type == "userdata" then
        return true
    end
    return false
end

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function name_without_hex(name)
    local s = ''
    local inSlash = false
    for i = 1, #name do
        local c = name:sub(i,i)
        if c == '\\' then
            inSlash = not inSlash
        elseif not inSlash then
            s = s .. c
        end
    end
    return s
end

function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end

function needlemouse_in_server()
    for i = 0, (MAX_PLAYERS - 1) do
        if network_discord_id_from_local_index(i) == "361984642590441474" then
            return true
        end
    end
    return false
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

--- @param m MarioState
function mario_set_full_health(m)
    m.health = 0x880
    m.healCounter = 0
    m.hurtCounter = 0
end