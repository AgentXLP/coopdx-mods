-- name: Breaking Bad Death Cutscene
-- incompatible: death-cutscene bb-death arena
-- description: Breaking Bad Death Cutscene v1.0.2\nBy \\#ec7731\\AgentX\n\n\\#dcdcdc\\This mod replaces the normal death sequence with the final shot of Breaking Bad where the camera pans away from Walter White's body. Bubbling is automatically disabled and the sequence is only triggered by dying\nstanding, on your back, on your stomach, suffocating, being electrocuted or drowning.\n\nWhen a player dies, the music will play\nand get louder the closer you are to the body and quieter the farther away.\nThe vanilla music also fades out the closer you are to the body.\n\nPress A or B to skip the cutscene.\n\nRun /bb-gameover to toggle the death cutscene only playing if you have 0 lives left.
-- pausable: true

-- localize functions to improve performance
local audio_stream_load,allocate_mario_action,set_character_anim_with_accel,vec3f_set,audio_stream_set_position,vec3f_copy,audio_stream_get_position,dist_between_objects,audio_stream_set_volume,fade_volume_scale,clampf,level_trigger_warp,get_current_background_music,stop_background_music,audio_stream_play,camera_unfreeze,hud_show,audio_stream_stop,sound_banks_enable,set_mario_action,camera_freeze,hud_hide,sound_banks_disable,djui_chat_message_create = audio_stream_load,allocate_mario_action,set_character_anim_with_accel,vec3f_set,audio_stream_set_position,vec3f_copy,audio_stream_get_position,dist_between_objects,audio_stream_set_volume,fade_volume_scale,clampf,level_trigger_warp,get_current_background_music,stop_background_music,audio_stream_play,camera_unfreeze,hud_show,audio_stream_stop,sound_banks_enable,set_mario_action,camera_freeze,hud_hide,sound_banks_disable,djui_chat_message_create

local STREAM_BABY_BLUE = audio_stream_load("baby_blue.ogg")

local PACKET_MUSIC = 0

local ACT_BB_DEATH = allocate_mario_action(ACT_GROUP_CUTSCENE | ACT_FLAG_STATIONARY | ACT_FLAG_INTANGIBLE | ACT_FLAG_INVULNERABLE)

local sCutsceneState = {
    playing = false,
    timer = 0
}

local gameoverMode = false

--- @param value boolean
--- Returns an on or off string depending on value
local function on_or_off(value)
    if value then return "\\#00ff00\\ON" end
    return "\\#ff0000\\OFF"
end

--- @param m MarioState
--- Checks if a player is currently active
local function active_player(m)
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

--- @param reliable boolean
--- @param packet integer
--- @param dataTable table
--- Sends a packet with the level, area, and act it came from
local function packet_send(reliable, packet, dataTable)
    dataTable = dataTable or {}
    dataTable.id = packet
    dataTable.level = gNetworkPlayers[0].currLevelNum
    dataTable.area = gNetworkPlayers[0].currAreaIndex
    dataTable.act = gNetworkPlayers[0].currActNum
    network_send(reliable, dataTable)
end

--- @param action integer
--- Checks if the action is one suitable for the death cutscene to play from
local function is_death_action_acceptable(action)
    return action == ACT_DEATH_ON_BACK or
        action == ACT_DEATH_ON_STOMACH or
        action == ACT_STANDING_DEATH or
        action == ACT_ELECTROCUTION or
        action == ACT_SUFFOCATION or
        action == ACT_DROWNING
end

--- Checks if Day Night Cycle DX v2.1 or greater is enabled
local function is_dnc_mod_enabled()
    return _G.dayNightCycleApi ~= nil and _G.dayNightCycleApi.version ~= nil -- check version since that will be a new field in Day Night Cycle DX v2.1 
end

--- @param m MarioState
--- He's dead, Jim.
local function act_bb_death(m)
    set_character_anim_with_accel(m, CHAR_ANIM_DYING_ON_BACK, 0)
    m.marioObj.header.gfx.animInfo.animFrame = 55
    m.marioBodyState.eyeState = MARIO_EYES_DEAD
    if m.playerIndex == 0 then
        vec3f_set(m.marioObj.header.gfx.angle, 0, 0x8000, 0)

        if (m.controller.buttonPressed & (A_BUTTON | B_BUTTON)) ~= 0 then
            sCutsceneState.timer = 1740
            audio_stream_set_position(STREAM_BABY_BLUE, 61)
        end
    end

    vec3f_copy(m.marioObj.header.gfx.pos, m.pos)
    return 0
end

local function update()
    -- for players that aren't the ones dying
    if audio_stream_get_position(STREAM_BABY_BLUE) ~= 0 and gMarioStates[0].action ~= ACT_BB_DEATH and not is_death_action_acceptable(gMarioStates[0].action) then
        -- get the nearest Mario in the death cutscene
        local nearest = nil
        local nearestDist = 0
        local count = 0
        for i = 1, MAX_PLAYERS - 1 do
            local m = gMarioStates[i]
            if active_player(m) and m.action == ACT_BB_DEATH then
                local dist = dist_between_objects(gMarioStates[0].marioObj, gMarioStates[i].marioObj)
                if nearest == nil or dist < nearestDist then
                    nearest = gMarioStates[i]
                    nearestDist = dist
                    count = count + 1
                end
            end
        end

        -- if no Marios are found and the music is still playing, "stop" it
        if count == 0 then
            audio_stream_set_position(STREAM_BABY_BLUE, 0.0)
            audio_stream_set_volume(STREAM_BABY_BLUE, 0.0)
            fade_volume_scale(SEQ_PLAYER_LEVEL, 127, 1)
            if is_dnc_mod_enabled() then
                _G.dayNightCycleApi.playNightMusic = true
            end
            return
        end

        -- calculate music volume
        local volume = clampf((600 / nearestDist), 0, 1)
        audio_stream_set_volume(STREAM_BABY_BLUE, volume)
        fade_volume_scale(SEQ_PLAYER_LEVEL, (1 - volume) * 127, 1)

        return
    end

    -- for players that are the ones dying
    if not sCutsceneState.playing then return end

    -- stay still at first but start panning away
    --- @type MarioState
    local m = gMarioStates[0]
    if sCutsceneState.timer < 30 then
        vec3f_set(gLakituState.pos, m.pos.x - 10, m.pos.y + 120, m.pos.z + 60)
        vec3f_set(gLakituState.focus, gLakituState.pos.x + 1, m.pos.y, gLakituState.pos.z + 1)
        gLakituState.roll = 0x2500
    elseif sCutsceneState.timer < 1770 then
        local timer = sCutsceneState.timer - 30
        vec3f_set(gLakituState.pos, m.pos.x - 10, m.pos.y + 120 + timer * 0.7, m.pos.z + 60 - timer * 0.04)
        vec3f_set(gLakituState.focus, gLakituState.pos.x + 1, m.pos.y, gLakituState.pos.z + 1)
        gLakituState.roll = 0x2500 - 13 * timer
    end

    -- increment the timer and trigger the ending screen if the time has come
    sCutsceneState.timer = sCutsceneState.timer + 1
    if sCutsceneState.timer == 1770 then
        level_trigger_warp(m, WARP_OP_CREDITS_END)
    end
end

--- @param m MarioState
local function on_set_mario_action(m)
    -- for the local player if they're dying
    if m.playerIndex ~= 0 then return end
    if gameoverMode and m.numLives > 0 then return end

    if is_death_action_acceptable(m.action) then
        stop_background_music(get_current_background_music())
        audio_stream_play(STREAM_BABY_BLUE, true, 1.0)
        packet_send(true, PACKET_MUSIC, {})
        if is_dnc_mod_enabled() then
            _G.dayNightCycleApi.playNightMusic = false
        end
    elseif m.action == ACT_BB_DEATH then
        stop_background_music(get_current_background_music()) -- just to make sure
    end
end

local function on_level_init()
    if not sCutsceneState.playing then return end

    -- reset cutscene state
    sCutsceneState.playing = false
    sCutsceneState.timer = 0
    camera_unfreeze()
    hud_show()
    audio_stream_stop(STREAM_BABY_BLUE)
    audio_stream_set_position(STREAM_BABY_BLUE, 0.0)
    sound_banks_enable(SEQ_PLAYER_SFX, SOUND_BANKS_ALL)

    -- reset DNC API fields
    if is_dnc_mod_enabled() then
        _G.dayNightCycleApi.displayTime = true
        _G.dayNightCycleApi.playNightMusic = true
    end
end

--- @param m MarioState
local function on_death(m)
    if gameoverMode and m.numLives > 0 then return true end

    -- setup the death cutscene
    if is_death_action_acceptable(m.action) then
        m.numLives = m.numLives - 1
        if m.numLives < 0 then
            m.numLives = 4
        end
        if m.action == ACT_DROWNING then
            m.pos.y = m.waterLevel - 20
        end
        set_mario_action(m, ACT_BB_DEATH, 0)
        camera_freeze()
        hud_hide()
        sound_banks_disable(SEQ_PLAYER_SFX, SOUND_BANKS_ALL)
        if is_dnc_mod_enabled() then
            _G.dayNightCycleApi.displayTime = false
        end
        sCutsceneState.playing = true
        return false
    end

    return true
end

local function on_packet_receive(dataTable)
    if gNetworkPlayers[0].currLevelNum ~= dataTable.level or gNetworkPlayers[0].currAreaIndex ~= dataTable.area or gNetworkPlayers[0].currActNum ~= dataTable.act then return end
    if gMarioStates[0].action == ACT_BB_DEATH then return end

    if dataTable.id == PACKET_MUSIC and audio_stream_get_position(STREAM_BABY_BLUE) == 0.0 then
        if is_dnc_mod_enabled() then
            _G.dayNightCycleApi.playNightMusic = false
        end
        audio_stream_play(STREAM_BABY_BLUE, true, 0.0)
    end
end


local function on_bb_gameover_command()
    gameoverMode = not gameoverMode
    djui_chat_message_create("[Breaking Bad Death Cutscene] Game Over Mode: " .. on_or_off(gameoverMode))
    return true
end

gServerSettings.bubbleDeath = false

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_SET_MARIO_ACTION, on_set_mario_action)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_DEATH, on_death)
hook_event(HOOK_ON_PACKET_RECEIVE, on_packet_receive)

hook_mario_action(ACT_BB_DEATH, act_bb_death)

hook_chat_command("bb-gameover", "- To toggle the option of only triggering the cutscene when you are going to Game Over", on_bb_gameover_command)