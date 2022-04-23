-- name: xutils
-- description: utility library by Agent X that just hosts various functions

function in_range(val, low, max)
    return val >= low and val <= max
end

function disable_fall_damage(m)
    m.peakHeight = m.pos.y
end

function print_face_angle()
    djui_hud_print_text(tostring(gMarioStates[0].faceAngle.y), djui_hud_get_screen_width() * 0.5, djui_hud_get_screen_height() - 20, 1)
end