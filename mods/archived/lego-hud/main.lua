-- name: LEGO HUD
-- incompatible: hud
-- description: Left 4 Dead 2 HUD\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds the LEGO HUD into sm64ex-coop with the stud bar, True Jedi, minikits, bricks and studs.

E_MODEL_CHALLENGE_MINIKIT = smlua_model_util_get_id("challenge_minikit_geo")

SOUND_CUSTOM_TRUE_JEDI = audio_sample_load("truejedi.mp3")
SOUND_CUSTOM_MINIKIT = audio_sample_load("minikit.mp3")

TEX_HEART = get_texture_info("heart")
TEX_HEART_HALF = get_texture_info("heart_half")
TEX_HEART_EMPTY = get_texture_info("heart_empty")
TEX_CIRCLE = get_texture_info("circle")

LOW_STUD_BRIGHTNESS = 25

STUD_BAR_EMPHASIZING = 0
STUD_BAR_DEEMPHASIZING = 1

STUD_BAR_Y = 17

studBarState = STUD_BAR_DEEMPHASIZING

excludedTrueJediLevels = {
    [LEVEL_TOTWC] = true,
    [LEVEL_COTMC] = true,
    [LEVEL_VCUTM] = true,
    [LEVEL_BITDW] = true,
    [LEVEL_BITFS] = true,
    [LEVEL_BITS] = true,
    [LEVEL_BOWSER_1] = true,
    [LEVEL_BOWSER_2] = true,
    [LEVEL_BOWSER_3] = true,
    [LEVEL_SA] = true,
    [LEVEL_WMOTR] = true,
    [LEVEL_PSS] = true
}

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

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

function lerp(a,b,t) return a * (1-t) + b * t end

function damp(a, b, x, dt) return a + (b - a) * (1.0 - math.exp(-x * dt)) end

function normalize(number) return tostring(number):gsub("-", "M") end

function update()
    local obj = obj_get_first_with_behavior_id(id_bhvRedCoin)
    while obj ~= nil do
        obj.header.gfx.node.flags = GRAPH_RENDER_ACTIVE
        obj.oFaceAngleYaw = obj.oFaceAngleYaw + 0x400
        obj.oGraphYOffset = 50

        obj = obj_get_next_with_same_behavior_id(obj)
    end

    local grandStar = obj_get_first_with_behavior_id(id_bhvGrandStar)
    if grandStar ~= nil then
        obj_set_model_extended(grandStar, E_MODEL_CHALLENGE_MINIKIT)
    end
    if gMarioStates[0].action == ACT_END_PEACH_CUTSCENE then
        local star = obj_get_first_with_behavior_id(id_bhvStaticObject)
        star = obj_get_next_with_same_behavior_id(star)
        if star ~= nil then obj_set_model_extended(star, E_MODEL_CHALLENGE_MINIKIT) end
    end
end

--- @param m MarioState
--- @param o Object
function on_interact(m, o, type, value)
    if get_id_from_behavior(o.behavior) == id_bhvRedCoin then
        audio_sample_play(SOUND_CUSTOM_MINIKIT, m.pos, 1)
    end
end

coinsBuffer = 0
timeSinceCollectedCoin = 0
dampTime = 0
studBarFlashIndex = 1
barY = -25
function on_hud_render()
    hud_hide()
    if obj_get_first_with_behavior_id(id_bhvActSelector) ~= nil or gNetworkPlayers[0].currActNum == 99 or gNetworkPlayers[0].currLevelNum == LEVEL_ENDING then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_MENU)

    local width = djui_hud_get_screen_width()
    local centerX = width * 0.5
    local studBarScale = 1.3

    timeSinceCollectedCoin = timeSinceCollectedCoin + 1
    dampTime = dampTime + 1

    if hud_get_value(HUD_DISPLAY_COINS) ~= coinsBuffer then
        studBarState = STUD_BAR_EMPHASIZING
        timeSinceCollectedCoin = 0
        if barY <= -25 then dampTime = 0 end
        obj_mark_for_deletion(nil)

        if hud_get_value(HUD_DISPLAY_COINS) == 100 and coinsBuffer == 99 then
            djui_popup_create("\\#ffff00\\100% True Plumber", 1)
            audio_sample_play(SOUND_CUSTOM_TRUE_JEDI, gMarioStates[0].pos, 2)
        end

        coinsBuffer = hud_get_value(HUD_DISPLAY_COINS)
    end

    -- 100% true plumber
    if gNetworkPlayers[0].currCourseNum ~= COURSE_NONE and excludedTrueJediLevels[gNetworkPlayers[0].currLevelNum] == nil then
        if timeSinceCollectedCoin > 90 and studBarState == STUD_BAR_EMPHASIZING then studBarState = STUD_BAR_DEEMPHASIZING end

        if studBarState == STUD_BAR_DEEMPHASIZING then
            barY = approach_number(barY, -25, 2.5, 2.5)
        else
            barY = damp(-25, STUD_BAR_Y, dampTime / 15, 3)
        end

        if coinsBuffer >= 100 then barY = STUD_BAR_Y end

        local add = -38
        for i = 1, 10 do
            if coinsBuffer < 100 then
                if coinsBuffer >= 10 * i then
                    djui_hud_set_adjusted_color(255, 255, 255, 255)
                else
                    local t = clamp((coinsBuffer - (10 * (i - 1))) * 0.1, 0, 1) -- what the f**k
                    local lerp = lerp(LOW_STUD_BRIGHTNESS, 255, t)
                    djui_hud_set_adjusted_color(lerp, lerp, lerp, 255)
                end
            else
                local index = math.floor(studBarFlashIndex)
                if i == index then
                    djui_hud_set_adjusted_color(255, 255, 255, 255)
                else
                    local brightness = LOW_STUD_BRIGHTNESS
                    if i == index + 1 or i == index - 1 then
                        brightness = 255 - (25.5 * 2)
                    elseif i == index + 2 or i == index - 2 then
                        brightness = 255 - (25.5 * 3)
                    elseif i == index + 3 or i == index - 3 then
                        brightness = 255 - (25.5 * 4)
                    end
                    djui_hud_set_adjusted_color(brightness, brightness, brightness, 255)
                end
            end
            djui_hud_render_texture(gTextures.coin, centerX + (add * studBarScale), barY, 1.25 * studBarScale, 1 * studBarScale)
            add = add + 7
        end
        studBarFlashIndex = studBarFlashIndex + 0.25
        if studBarFlashIndex < 1 then studBarFlashIndex = 10 end
        if studBarFlashIndex > 10 then studBarFlashIndex = 1 end
    end

    -- info
    djui_hud_set_adjusted_color(255, 255, 255, 255)
    djui_hud_render_texture(TEX_CIRCLE, 10, 10, 0.25, 0.25)
    djui_hud_render_texture(gMarioStates[0].character.hudHeadTexture, 18, 16, 1, 1)
    djui_hud_render_texture(gTextures.coin, 42, 12, 0.75, 0.75)
    djui_hud_set_adjusted_color(255, 240, 0, 255)
    djui_hud_print_text(tostring(coinsBuffer), 53, 10, 0.25)

    local measurement = djui_hud_measure_text(tostring(coinsBuffer)) * 0.25
    djui_hud_render_texture(gTextures.star, 58 + measurement, 12, 0.75, 0.75)

    -- lives under head
    local lives = normalize(hud_get_value(HUD_DISPLAY_LIVES))
    djui_hud_print_text(lives, 30 - (6 * string.len(lives)), 26, 0.25)

    djui_hud_print_text("x ", 71 + measurement, 10, 0.25)
    djui_hud_print_text(normalize(hud_get_value(HUD_DISPLAY_STARS)), 81 + measurement, 10, 0.25)

    -- hearts
    local health = math.floor(gMarioStates[0].health / 272)

    if health >= 2 then
        djui_hud_render_texture(TEX_HEART, 44, 25, 0.4, 0.4)
    elseif health < 2 and health >= 1 then
        djui_hud_render_texture(TEX_HEART_HALF, 44, 25, 0.4, 0.4)
    else
        djui_hud_render_texture(TEX_HEART_EMPTY, 44, 25, 0.4, 0.4)
    end

    if health >= 4 then
        djui_hud_render_texture(TEX_HEART, 44 + 13 * 1, 25, 0.4, 0.4)
    elseif health < 4 and health >= 3 then
        djui_hud_render_texture(TEX_HEART_HALF, 44 + 13 * 1, 25, 0.4, 0.4)
    else
        djui_hud_render_texture(TEX_HEART_EMPTY, 44 + 13 * 1, 25, 0.4, 0.4)
    end

    if health >= 6 then
        djui_hud_render_texture(TEX_HEART, 44 + 13 * 2, 25, 0.4, 0.4)
    elseif health < 6 and health >= 5 then
        djui_hud_render_texture(TEX_HEART_HALF, 44 + 13 * 2, 25, 0.4, 0.4)
    else
        djui_hud_render_texture(TEX_HEART_EMPTY, 44 + 13 * 2, 25, 0.4, 0.4)
    end

    if health >= 8 then
        djui_hud_render_texture(TEX_HEART, 44 + 13 * 3, 25, 0.4, 0.4)
    elseif health < 8 and health >= 7 then
        djui_hud_render_texture(TEX_HEART_HALF, 44 + 13 * 3, 25, 0.4, 0.4)
    else
        djui_hud_render_texture(TEX_HEART_EMPTY, 44 + 13 * 3, 25, 0.4, 0.4)
    end

    -- timer
    local timer = hud_get_value(HUD_DISPLAY_TIMER)

    if timer > 0 then
        local timerText = tostring(math.floor(timer / 30))
        djui_hud_set_font(FONT_MENU)
        djui_hud_set_adjusted_color(230, 14, 232, 255)
        djui_hud_print_text(timerText, width * 0.5 - (djui_hud_measure_text(timerText) * 0.5), 35, 0.5)
    end
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)