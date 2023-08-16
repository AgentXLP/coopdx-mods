-- localize functions to improve performance
local is_player_active,get_behavior_from_id,get_object_list_from_behavior,obj_get_first,get_id_from_behavior,obj_get_next,obj_copy_angle,is_game_paused,djui_hud_set_color,obj_get_first_with_behavior_id,obj_mark_for_deletion,obj_get_next_with_same_behavior_id,table_insert,djui_hud_measure_text,djui_hud_print_text,set_lighting_color,math_floor,mod_storage_load,djui_hud_set_rotation,vec3f_dist,djui_hud_set_font,cur_obj_become_tangible,warp_to_level,smlua_text_utils_get_language = is_player_active,get_behavior_from_id,get_object_list_from_behavior,obj_get_first,get_id_from_behavior,obj_get_next,obj_copy_angle,is_game_paused,djui_hud_set_color,obj_get_first_with_behavior_id,obj_mark_for_deletion,obj_get_next_with_same_behavior_id,table.insert,djui_hud_measure_text,djui_hud_print_text,set_lighting_color,math.floor,mod_storage_load,djui_hud_set_rotation,vec3f_dist,djui_hud_set_font,cur_obj_become_tangible,warp_to_level,smlua_text_utils_get_language

function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
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

--- @return number?
function bool_tonumber(e)
    if type(e) == "boolean" then
        return if_then_else(e, 1, 0)
    end

    return tonumber(e)
end

function lerp(a, b, t) return a * (1 - t) + b * t end

-- eases in and out
function smooth_lerp(a, b, t)
    t = t * t * (3 - 2 * t)
    return a + (b - a) * t
end

--- @param o Object
function dist_to_pos(o, pos)
    local x = o.oPosX - pos.x x = x * x
    local y = o.oPosY - pos.y y = y * y
    local z = o.oPosZ - pos.z z = z * z
    return math.sqrt(x + y + z)
end

--- @param behaviorId BehaviorId
--- @param pos Vec3f
--- @return Object|nil
function find_nearest_star(behaviorId, pos, minDist)
    local closestObj = nil
    local obj = obj_get_first(get_object_list_from_behavior(get_behavior_from_id(behaviorId)))

    while obj ~= nil do
        if get_id_from_behavior(obj.behavior) == behaviorId and obj.activeFlags ~= ACTIVE_FLAG_DEACTIVATED then
            local objDist = dist_to_pos(obj, pos)
            if objDist < minDist then
                closestObj = obj
                minDist = objDist
            end
        end
        obj = obj_get_next(obj)
    end

    return closestObj
end

--- @param parent Object
--- @param model ModelExtendedId
--- @param behavior BehaviorId
--- @return Object|nil
function spawn_object(parent, model, behavior, sync)
    local func = if_then_else(sync, spawn_sync_object, spawn_non_sync_object)

    local obj = func(
        behavior,
        model,
        parent.oPosX, parent.oPosY, parent.oPosZ,
        --- @param o Object
        function(o)
            obj_copy_angle(o, parent)
        end
    )
    if obj == nil then return nil end

    return obj
end

function SEQUENCE_ARGS(priority, seqId)
    return ((priority << 8) | seqId)
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

--- @param behaviorId BehaviorId
function delete_every_object_with_behavior_id(behaviorId)
    local obj = obj_get_first_with_behavior_id(behaviorId)
    while obj ~= nil do
        obj_mark_for_deletion(obj)
        obj = obj_get_next_with_same_behavior_id(obj)
    end
end

function for_each_object_with_behavior(behavior, funcF)
    local obj = obj_get_first_with_behavior_id(behavior)
    while obj ~= nil do
        funcF(obj)
        obj = obj_get_next_with_same_behavior_id(obj)
    end
end

function split_string(string, interval)
    local splitTable = {}
    local index = 1

    while index <= #string do
      local chunk = string.sub(string, index, index + interval - 1)
      table.insert(splitTable, chunk)
      index = index + interval
    end

    return splitTable
end

function djui_hud_print_text_centered(message, x, y, scale)
    local measure = djui_hud_measure_text(message)
    djui_hud_print_text(message, x - (measure * 0.5) * scale, y, scale)
end

function tint_lighting_color()
    set_lighting_color(0, 127)
    set_lighting_color(1, 255)
    set_lighting_color(2, 255)
end

function reset_lighting_color()
    set_lighting_color(0, 255)
    set_lighting_color(1, 255)
    set_lighting_color(2, 255)
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

function s16(num)
    num = math.floor(num) & 0xFFFF
    if num >= 32768 then return num - 65536 end
    return num
end

function mod_storage_get_total_star_count()
    local count = 0
    for i = 1, STARS do
        if mod_storage_load(i .. "_collected") == "true" then
            count = count + 1
        end
    end
    return count
end

--- @param m MarioState
--- @param target Object
--- @param iconTexture TextureInfo
function render_hud_radar(m, target, iconTexture, texW, texH, x, y)
    djui_hud_render_texture(iconTexture, x, y, texW, texH)

    -- direction
    local angle = s16(
        atan2s(
            target.oPosZ - m.pos.z,
            target.oPosX - m.pos.x
        ) - atan2s(
            m.pos.z - gLakituState.pos.z,
            m.pos.x - gLakituState.pos.x
        )
    )

    djui_hud_set_rotation(angle, 0.5, 2.5)
    djui_hud_render_texture(gTextures.arrow_up, x + 4, y - 12, 1, 1)
    djui_hud_set_rotation(0, 0, 0)

    -- distance
    local dist = vec3f_dist({ x = target.oPosX, y = target.oPosY, z = target.oPosZ }, m.pos)
    djui_hud_set_font(FONT_HUD)
    djui_hud_print_text(tostring(math.floor(dist * 0.01)), x + 24, y, 1)
end

--- @param obj Object
--- @param hitbox ObjectHitbox
function obj_set_hitbox(obj, hitbox)
    if not obj or not hitbox then return end
    -- As far as I can tell, this is used to 
    -- force the hitboxes to be set only once
    if (obj.oFlags & OBJ_FLAG_30) == 0 then
        obj.oFlags = obj.oFlags | OBJ_FLAG_30

        -- obj.oInteractType = hitbox.interactType
        obj.oDamageOrCoinValue = hitbox.damageOrCoinValue
        obj.oHealth = hitbox.health
        obj.oNumLootCoins = hitbox.numLootCoins

        cur_obj_become_tangible()
    end

    obj.hitboxRadius = obj.header.gfx.scale.x * hitbox.radius
    obj.hitboxHeight = obj.header.gfx.scale.y * hitbox.height
    obj.hurtboxRadius = obj.header.gfx.scale.x * hitbox.hurtboxRadius
    obj.hurtboxHeight = obj.header.gfx.scale.y * hitbox.hurtboxHeight
    obj.hitboxDownOffset = obj.header.gfx.scale.y * hitbox.downOffset
end

function warp_to_level_global(aLevel, aArea, aAct)
    gGlobalSyncTable.level = aLevel
    warp_to_level(aLevel, aArea, aAct)
end

function obj_get_star_by_id(id)
    local star = obj_get_first_with_behavior_id(id_bhvStar)
    while star ~= nil do
        if (star.oBehParams >> 24) + 1 == id then
            return star
        end
        star = obj_get_next_with_same_behavior_id(star)
    end
    return nil
end

function get_factor(number)
    local factors = 0
    local factor = 0
    while factor < 1 do
        factor = factor + number
        factors = factors + 1
    end
    return factors
end

function get_language()
    local language = smlua_text_utils_get_language()
    if not gLanguages[language] then return "English" end

    return language
end

function XLANG(text)
    if gLocalizedText[text] == nil or gLocalizedText[text][get_language()] == nil then return text end

    return gLocalizedText[text][get_language()]
end

local courseToLevel = {
    [COURSE_NONE] = LEVEL_NONE,
    [COURSE_BOB] = LEVEL_BOB,
    [COURSE_WF] = LEVEL_WF,
    [COURSE_JRB] = LEVEL_JRB,
    [COURSE_CCM] = LEVEL_CCM,
    [COURSE_BBH] = LEVEL_BBH,
    [COURSE_HMC] = LEVEL_HMC,
    [COURSE_LLL] = LEVEL_LLL,
    [COURSE_SSL] = LEVEL_SSL,
    [COURSE_DDD] = LEVEL_DDD,
    [COURSE_SL] = LEVEL_SL,
    [COURSE_WDW] = LEVEL_WDW,
    [COURSE_TTM] = LEVEL_TTM,
    [COURSE_THI] = LEVEL_THI,
    [COURSE_TTC] = LEVEL_TTC,
    [COURSE_RR] = LEVEL_RR,
    [COURSE_BITDW] = LEVEL_BITDW,
    [COURSE_BITFS] = LEVEL_BITFS,
    [COURSE_BITS] = LEVEL_BITS,
    [COURSE_PSS] = LEVEL_PSS,
    [COURSE_COTMC] = LEVEL_COTMC,
    [COURSE_TOTWC] = LEVEL_TOTWC,
    [COURSE_VCUTM] = LEVEL_VCUTM,
    [COURSE_WMOTR] = LEVEL_WMOTR,
    [COURSE_SA] = LEVEL_SA,
    [COURSE_CAKE_END] = LEVEL_ENDING,
}

function course_to_level(course)
    return courseToLevel[course] or LEVEL_NONE
end