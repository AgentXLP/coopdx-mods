function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
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

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
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

--- @param m MarioState
function disable_fall_damage(m)
    m.peakHeight = m.pos.y
end

--- @param m MarioState
function sparkle_if_twirling(m)
    if m.action == ACT_TWIRLING and gNetworkPlayers[0].currLevelNum == LEVEL_PSS then m.particleFlags = m.particleFlags | PARTICLE_SPARKLES end
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
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

smlua_audio_utils_replace_sequence(SEQ_LEVEL_SLIDE, 37, 80, "00_pinball_custom")

-- dynos moment
function on_warp()
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS then gMarioStates[0].faceAngle.y = gMarioStates[0].faceAngle.y + 0x8000 end
end

hook_event(HOOK_ON_WARP, on_warp)