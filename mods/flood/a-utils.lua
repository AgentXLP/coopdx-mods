sOverrideCameraModes = {
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

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
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

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

-- Rounds down or up depending on the decimal position of `x`.
--- @param x number
--- @return integer
math.round = function(x)
    return if_then_else(x - math.floor(x) >= 0.5, math.ceil(x), math.floor(x))
end

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

function flood_get_start_water_level()
    local start = gLevels[gGlobalSyncTable.level].customStartPos
    if start ~= nil then
        return find_floor_height(start.x, start.y, start.z) - 1200
    else
        -- only sub areas have a weird issue where this function appears to always return the floor lower limit on level init
        return if_then_else(gLevels[gGlobalSyncTable.level].area == 1, find_floor_height(gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z), gMarioStates[0].pos.y) - 1200
    end
end

--- @param m MarioState
function mario_set_full_health(m)
    m.health = 0x880
    m.healCounter = 0
    m.hurtCounter = 0
end