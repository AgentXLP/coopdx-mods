-- localize functions to improve performance
local math_floor = math.floor
local table_insert = table.insert
local djui_hud_set_color = djui_hud_set_color
local mod_storage_load = mod_storage_load
local mod_storage_save = mod_storage_save
local obj_mark_for_deletion = obj_mark_for_deletion
local get_skybox = get_skybox
local hud_is_hidden = hud_is_hidden
local is_game_paused = is_game_paused

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
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
        table_insert(result, match)
    end
    return result
end

function lerp(a,b,t) return a * (1-t) + b * t end

--- @param a Color
--- @param b Color
function color_lerp(a, b, t)
    return {
        r = lerp(a.r, b.r, t),
        g = lerp(a.g, b.g, t),
        b = lerp(a.b, b.b, t),
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
    return not gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] and get_skybox() ~= -1
end

function get_day_count()
    return math_floor(gGlobalSyncTable.time / (MINUTE * 24))
end

function save_time()
    mod_storage_save("time", tostring(gGlobalSyncTable.time))
    print("Saving time to 'day-night-cycle.sav'")
end

function load_time()
    local time = tonumber(mod_storage_load("time"))
    if time == nil then
        time = MINUTE * 6
        mod_storage_save("time", tostring(time))
    end
    return time
end

function common_hud_hide_requirements()
    return gNetworkPlayers[0].currActNum == 99 or hud_is_hidden()
end

--- @param o Object
local function delete_at_dark(o)
    local minutes = gGlobalSyncTable.time / MINUTE % 24

    if minutes < 5 or minutes > 7 then
       obj_mark_for_deletion(o)
    end
end

id_bhvBirdsSoundLoop = hook_behavior(id_bhvBirdsSoundLoop, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)
id_bhvBird = hook_behavior(id_bhvBird, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)
id_bhvButterfly = hook_behavior(id_bhvButterfly, OBJ_LIST_DEFAULT, false, nil, delete_at_dark)