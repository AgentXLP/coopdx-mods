-- name: Completion Percentage
-- description: Completion Percentage\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds a completion percentage to sm64ex-coop in the pause menu, when you're not in a course and pause the game there will be a percentage near the middle of the screen.

NUM_STARS = 120
-- stars, ddd moved back, moat drained, 3 caps, 9 unlockable doors
NUM_OBJECTIVES = NUM_STARS + 1 + 1 + 3 + 9

function increment_completion(completion)
    return completion + (1 - (NUM_STARS / NUM_OBJECTIVES)) / (NUM_OBJECTIVES - NUM_STARS)
end

function djui_hud_print_text_centered(message, x, y, scale)
    local measure = djui_hud_measure_text(message)
    djui_hud_print_text(message, x - (measure * 0.5) * scale, y, scale)
end

function on_hud_render()
    if not is_game_paused() or gNetworkPlayers[0].currCourseNum ~= COURSE_NONE then return end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local width = djui_hud_get_screen_width()
    local height = djui_hud_get_screen_height()

    local completion = gMarioStates[0].numStars / NUM_OBJECTIVES
    local flags = save_file_get_flags()
    if (flags & SAVE_FLAG_DDD_MOVED_BACK) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_HAVE_WING_CAP) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_HAVE_METAL_CAP) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_HAVE_VANISH_CAP) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_MOAT_DRAINED) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_PSS_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_WF_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_CCM_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_JRB_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_BITDW_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_BASEMENT_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_BITFS_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_UPSTAIRS_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end
    if (flags & SAVE_FLAG_UNLOCKED_50_STAR_DOOR) ~= 0 then
        completion = increment_completion(completion)
    end

    djui_hud_set_color(0, 0, 0, 150)
    djui_hud_print_text_centered(string.format("%.2f", completion * 100) .. "%", width * 0.5, height * 0.5 - 19, 0.5)
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text_centered(string.format("%.2f", completion * 100) .. "%", width * 0.5, height * 0.5 - 20, 0.5)
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)