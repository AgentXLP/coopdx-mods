-- name: Mario Style
-- description: Mario Style\n\\#ffffff\\By \\#ff7f00\\Agent X\\#ffffff\\\n\nCollect a star and hit the Mario Style.

SOUND_CUSTOM_GANGNAM = audio_sample_load("gangnam.mp3")

-- support for other characters coming soon trust
--- @param m MarioState
function mario_update(m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_STAR_DANCE_EXIT or m.action == ACT_STAR_DANCE_NO_EXIT then play_secondary_music(SEQ_EVENT_CUTSCENE_COLLECT_STAR, 0, 0, 1) end
end

--- @param m MarioState
function on_set_mario_action(m)
    if m.playerIndex ~= 0 then return end

    if m.action == ACT_STAR_DANCE_EXIT or m.action == ACT_STAR_DANCE_NO_EXIT then
        audio_sample_play(SOUND_CUSTOM_GANGNAM, m.marioObj.header.gfx.cameraToObject, 5)
    elseif m.prevAction == ACT_STAR_DANCE_EXIT or m.prevAction == ACT_STAR_DANCE_NO_EXIT then
        play_secondary_music(SEQ_EVENT_CUTSCENE_COLLECT_STAR, get_current_background_music_target_volume(), 0, 1)
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)