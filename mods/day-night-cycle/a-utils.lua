if VERSION_NUMBER < 35 then
    local version = VERSION_TEXT .. " " .. VERSION_NUMBER
    djui_popup_create("\\#ffff00\\sm64ex-coop " .. version .. " is outdated and not supported with Day Night Cycle!\n\nPlease update to the latest version.", 4)
    return
end

-- localize functions to improve performance
local is_player_active,djui_hud_measure_text,djui_hud_print_text,table_insert,is_game_paused,djui_hud_set_color,get_skybox,math_floor,mod_storage_save,mod_storage_load,obj_mark_for_deletion = is_player_active,djui_hud_measure_text,djui_hud_print_text,table.insert,is_game_paused,djui_hud_set_color,get_skybox,math.floor,mod_storage_save,mod_storage_load,obj_mark_for_deletion

romhack = false
for mod in pairs(gActiveMods) do
    if gActiveMods[mod].incompatible == "romhack" then
        romhack = true
        break
    end
end

function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

--- @param m MarioState
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return 1
    end
    if not np.connected then
        return 0
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return 0
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return 0
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return 0
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return 0
    end
    return is_player_active(m)
end

function djui_hud_print_text_centered(message, x, y, scale)
    local measure = djui_hud_measure_text(message)
    djui_hud_print_text(message, x - (measure * 0.5) * scale, y, scale)
end

function approach_number(current, target, inc, dec)
    if current < target then
        current = current + inc
        if current > target then
            current = target
        end
    else
        current = current - dec
        if current < target then
            current = target
        end
    end
    return current
end

function split(s)
    local result = {}
    for match in (s):gmatch(string.format("[^%s]+", " ")) do
        table.insert(result, match)
    end
    return result
end

function lerp(a, b, t) return a * (1 - t) + b * t end

--- @param a Color
--- @param b Color
--- @return Color
function color_lerp(a, b, t)
    return {
        r = lerp(a.r, b.r, t),
        g = lerp(a.g, b.g, t),
        b = lerp(a.b, b.b, t)
    }
end

--- @param a Vec3f
--- @param b Vec3f
--- @return Vec3f
function vec3f_lerp(a, b, t)
    return {
        x = lerp(a.x, b.x, t),
        y = lerp(a.y, b.y, t),
        z = lerp(a.z, b.z, t)
    }
end

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

function format_number(number)
    local string = tostring(number)
    if number < 10 then
        string = "0" .. string
    end
    return string
end

function show_day_night_cycle()
    return (not gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] and get_skybox() ~= -1) or (romhack and get_skybox() ~= -1)
end

function get_day_count()
    return math.floor(gGlobalSyncTable.time / (MINUTE * 24))
end

function save_time()
    gGlobalSyncTable.time = math.floor(gGlobalSyncTable.time)
    mod_storage_save("time", tostring(gGlobalSyncTable.time))
    print("Saving time to 'day-night-cycle.sav'")
end

function load_time()
    local time = tonumber(mod_storage_load("time"))
    if time == nil then
        time = MINUTE * 5
        mod_storage_save("time", tostring(time))
    end
    return time
end

function get_time_string()
    local minutes = (gGlobalSyncTable.time / MINUTE) % 24
    local formattedMinutes = math.floor(minutes)
    local seconds = math.floor(gGlobalSyncTable.time / SECOND) % 60

    if useAMPM then
        if formattedMinutes == 0 then
            formattedMinutes = 12
        elseif formattedMinutes > 12 then
            formattedMinutes = formattedMinutes - 12
        end
    end

    return math.floor(formattedMinutes) .. ":" .. format_number(seconds) .. if_then_else(useAMPM, if_then_else(minutes < 12, " AM", " PM"), "")
end

--- @param o Object
local function delete_at_dark(o)
    local minutes = gGlobalSyncTable.time / MINUTE % 24

    if minutes < HOUR_SUNRISE_START or minutes > HOUR_SUNSET_END then
       obj_mark_for_deletion(o)
    end
end

id_bhvBirdsSoundLoop = hook_behavior(id_bhvBirdsSoundLoop, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)
id_bhvBird = hook_behavior(id_bhvBird, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)
id_bhvButterfly = hook_behavior(id_bhvButterfly, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)