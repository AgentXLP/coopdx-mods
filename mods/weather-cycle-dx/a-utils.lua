if not check_dnc_compatible() then return end

-- localize functions to improve performance
local djui_hud_get_color,djui_hud_set_color,djui_hud_print_text,djui_hud_measure_text,math_lerp,math_round,string_format,table_insert,math_floor,level_is_vanilla_level,type,math_random,mod_storage_load = djui_hud_get_color,djui_hud_set_color,djui_hud_print_text,djui_hud_measure_text,math.lerp,math.round,string.format,table.insert,math.floor,level_is_vanilla_level,type,math.random,mod_storage_load

--- @param cond boolean
--- Human readable ternary operator
function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- @param outlineBrightness number
--- Prints outlined DJUI HUD text
function djui_hud_print_outlined_text(message, x, y, scale, outlineBrightness)
    local color = djui_hud_get_color()
    djui_hud_set_color(color.r * outlineBrightness, color.g * outlineBrightness, color.b * outlineBrightness, color.a)
    djui_hud_print_text(message, x - 1, y, scale)
    djui_hud_print_text(message, x + 1, y, scale)
    djui_hud_print_text(message, x, y - 1, scale)
    djui_hud_print_text(message, x, y + 1, scale)
    djui_hud_set_color(color.r, color.g, color.b, color.a)
    djui_hud_print_text(message, x, y, scale)
end

--- @param message string
--- @param x number
--- @param y number
--- @param scale number
--- Prints DJUI HUD text that is horizontally anchored in the center
function djui_hud_print_centered_text(message, x, y, scale)
    local measure = djui_hud_measure_text(message)
    djui_hud_print_text(message, x - (measure * 0.5) * scale, y, scale)
end

--- @param a number
--- @param b number
--- @param t number
--- Linearly interpolates between two points using a delta but rounds the final value
function lerp_round(a, b, t)
    return math_round(math_lerp(a, b, t))
end

--- @param a Color
--- @param b Color
--- @param t number
--- @return Color
--- Linearly interpolates between two colors using a delta
function color_lerp(a, b, t)
    return {
        r = lerp_round(a.r, b.r, t),
        g = lerp_round(a.g, b.g, t),
        b = lerp_round(a.b, b.b, t)
    }
end

--- @param m MarioState
--- Checks if a player is currently active
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return false
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return false
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return false
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return false
    end
    return true
end

--- @param a Color
--- @param b Color
--- @return Color
--- Multiplies two colors together
function color_mul(a, b)
    return {
        r = a.r * (b.r / 255.0),
        g = a.g * (b.g / 255.0),
        b = a.b * (b.b / 255.0)
    }
end

--- @param s string
--- Splits a string into a table by spaces
function string_split(s)
    local result = {}
    for match in (s):gmatch(string_format("[^%s]+", " ")) do
        table_insert(result, match)
    end
    return result
end

--- @param value boolean
--- Returns an on or off string depending on value
function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end

--- @param timestamp integer
--- Formats the timestamp (in frames) into a time string formatted like XX:XX
function format_time(timestamp)
    local minutes = math_floor(timestamp / MINUTE)
    local seconds = math_floor(timestamp / SECOND) % 60
    return string_format("%d:%02d", minutes, seconds)
end

--- @param levelNum LevelNum
--- Returns whether or not the local player is in a vanilla level
function in_vanilla_level(levelNum)
    return gNetworkPlayers[0].currLevelNum == levelNum and level_is_vanilla_level(levelNum)
end

--- @param value number
--- Returns whether or not a number is an integer
function isinteger(value)
    if type(value) ~= "number" then return false end
    return value % 1 == 0
end

--- @param minRange integer
--- @param maxRange integer
--- Generates a random number between `minRange` and `maxRange` that isn't zero
function random_nonzero(minRange, maxRange)
    local random = math_random(minRange, maxRange)
    if not (minRange == 0 and maxRange == 0) then
        while random == 0 do
            random = math_random(minRange, maxRange)
        end
    end
    return random
end

--- @param levelNum LevelNum
--- Checks if any player is in a level
function any_player_in_level(levelNum)
    for i = 0, MAX_PLAYERS - 1 do
        if gNetworkPlayers[i].connected and gNetworkPlayers[i].currLevelNum == levelNum and level_is_vanilla_level(levelNum) then
            return true
        end
    end
    return false
end

--- @param levelNum LevelNum
--- Checks if any player is in a vanilla level
function any_player_in_vanilla_level(levelNum)
    return level_is_vanilla_level(levelNum) and any_player_in_level(levelNum)
end

--- @param key string
--- `mod_storage_load_bool` except it returns true by default
function mod_storage_load_bool_2(key)
    local value = mod_storage_load(key)
    if value == nil then return true end
    return value == "true"
end