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

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function normalize(number) return tostring(number):gsub("-", "M") end

function level_to_course(level)
    local levelToCourse = {
        [LEVEL_NONE] = COURSE_NONE,
        [LEVEL_BOB] = COURSE_BOB,
        [LEVEL_WF] = COURSE_WF,
        [LEVEL_JRB] = COURSE_JRB,
        [LEVEL_CCM] = COURSE_CCM,
        [LEVEL_BBH] = COURSE_BBH,
        [LEVEL_HMC] = COURSE_HMC,
        [LEVEL_LLL] = COURSE_LLL,
        [LEVEL_SSL] = COURSE_SSL,
        [LEVEL_DDD] = COURSE_DDD,
        [LEVEL_SL] = COURSE_SL,
        [LEVEL_WDW] = COURSE_WDW,
        [LEVEL_TTM] = COURSE_TTM,
        [LEVEL_THI] = COURSE_THI,
        [LEVEL_TTC] = COURSE_TTC,
        [LEVEL_RR] = COURSE_RR,
        [LEVEL_BITDW] = COURSE_BITDW,
        [LEVEL_BITFS] = COURSE_BITFS,
        [LEVEL_BITS] = COURSE_BITS,
        [LEVEL_PSS] = COURSE_PSS,
        [LEVEL_COTMC] = COURSE_COTMC,
        [LEVEL_TOTWC] = COURSE_TOTWC,
        [LEVEL_VCUTM] = COURSE_VCUTM,
        [LEVEL_WMOTR] = COURSE_WMOTR,
        [LEVEL_SA] = COURSE_SA,
        [LEVEL_ENDING] = COURSE_CAKE_END,
    }

    return levelToCourse[level] or COURSE_NONE
end

function play_djui_transition(fadeIn, time, red, green, blue)
    sDjuiTransition.color = { r = red, g = green, b = blue }
    sDjuiTransition.fadeIn = fadeIn
    sDjuiTransition.fadeAlpha = if_then_else(fadeIn, 255, 0)
    sDjuiTransition.time = time
end

function update_djui_transitions()
    if sDjuiTransition.fadeAlpha < 0 then return end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    if sDjuiTransition.fadeIn then
        sDjuiTransition.fadeAlpha = sDjuiTransition.fadeAlpha - (255 / sDjuiTransition.time)

        if sDjuiTransition.fadeAlpha < 0 then
            sDjuiTransition.fadeAlpha = -1
            return
        end
    else
        sDjuiTransition.fadeAlpha = sDjuiTransition.fadeAlpha + (255 / sDjuiTransition.time)

        if sDjuiTransition.fadeAlpha > 255 then
            sDjuiTransition.fadeAlpha = -1
            return
        end
    end
    djui_hud_set_color(sDjuiTransition.color.r, sDjuiTransition.color.g, sDjuiTransition.color.b, sDjuiTransition.fadeAlpha)
    djui_hud_render_rect(-2, -2, djui_hud_get_screen_width() + 2, djui_hud_get_screen_height() + 2)
end

--- @param o Object
function obj_nearest_painting_level(o)
    if o == nil then return LEVEL_NONE end
    local nearest = LEVEL_NONE
    local nearestDist = 0
    for k, v in pairs(gPaintingPositions) do
        local dist = 0
        if v[2] ~= nil then
            local dist1 = vec3f_dist({x = o.oPosX, y = o.oPosY, z = o.oPosZ }, v[1])
            local dist2 = vec3f_dist({x = o.oPosX, y = o.oPosY, z = o.oPosZ }, v[2])
            dist = math.min(dist1, dist2)
        else
            dist = vec3f_dist({x = o.oPosX, y = o.oPosY, z = o.oPosZ }, v[1])
        end
        if nearest == LEVEL_NONE or dist < nearestDist then
            nearest = k
            nearestDist = dist
        end
    end

    return nearest
end