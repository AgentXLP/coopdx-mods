gCustomCutscene = {
    playing = false,
    timer = 0,
    func = nil,
    prevCamPos = { x = 0, y = 0, z = 0 },
    prevCamFocus = { x = 0, y = 0, z = 0 }
}

local sCustomCutsceneGeneric = {
    pos = { x = 0, y = 0, z = 0 },
    focus = { x = 0, y = 0, z = 0 },
    time = 0,
    shake = false
}

local sCustomCutsceneApparitionBattle = {
    apparition = nil
}

gCustomCutsceneBetrayal = {
    apparition = nil,
    fadeTimer = 0
}

-- localize functions to improve performance
local vec3f_set,camera_unfreeze,camera_freeze,minf,obj_has_model_extended,play_sound,obj_set_model_extended,vec3f_copy,obj_mark_for_deletion,set_mario_action,audio_stream_stop,play_music,camera_is_frozen = vec3f_set,camera_unfreeze,camera_freeze,minf,obj_has_model_extended,play_sound,obj_set_model_extended,vec3f_copy,obj_mark_for_deletion,set_mario_action,audio_stream_stop,play_music,camera_is_frozen

function set_prev_cam_pos_and_focus()
    vec3f_set(gCustomCutscene.prevCamPos, gLakituState.pos.x, gLakituState.pos.y, gLakituState.pos.z)
    vec3f_set(gCustomCutscene.prevCamFocus, gLakituState.focus.x, gLakituState.focus.y, gLakituState.focus.z)
end

-- returns if a cutscene was playing prior to running the function
local function start_custom_cutscene(cutsceneFunc, overrideCurrent)
    if gCustomCutscene.playing and not overrideCurrent then
        return true
    end

    local wasPlaying = gCustomCutscene.playing
    gCustomCutscene.playing = true
    gCustomCutscene.timer = 0
    gCustomCutscene.func = cutsceneFunc
    set_prev_cam_pos_and_focus()

    return wasPlaying
end

function end_custom_cutscene()
    -- reset all other cutscenes
    vec3f_set(sCustomCutsceneGeneric.pos, 0, 0, 0)
    vec3f_set(sCustomCutsceneGeneric.focus, 0, 0, 0)
    sCustomCutsceneGeneric.time = 0
    sCustomCutsceneGeneric.shake = false
    sCustomCutsceneApparitionBattle.apparition = nil
    gCustomCutsceneBetrayal.apparition = nil

    gCustomCutscene.playing = false
    gCustomCutscene.timer = 0
    gCustomCutscene.func = nil
    camera_unfreeze()
    vec3f_set(gCustomCutscene.prevCamPos, 0, 0, 0)
    vec3f_set(gCustomCutscene.prevCamFocus, 0, 0, 0)
end

local function custom_cutscene_generic()
    camera_freeze()

    local t = minf(gCustomCutscene.timer / sCustomCutsceneGeneric.time, 1)
    local posX = smooth_lerp(gCustomCutscene.prevCamPos.x, sCustomCutsceneGeneric.pos.x + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)
    local posY = smooth_lerp(gCustomCutscene.prevCamPos.y, sCustomCutsceneGeneric.pos.y + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)
    local posZ = smooth_lerp(gCustomCutscene.prevCamPos.z, sCustomCutsceneGeneric.pos.z + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)

    local focX = smooth_lerp(gCustomCutscene.prevCamFocus.x, sCustomCutsceneGeneric.focus.x + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)
    local focY = smooth_lerp(gCustomCutscene.prevCamFocus.y, sCustomCutsceneGeneric.focus.y + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)
    local focZ = smooth_lerp(gCustomCutscene.prevCamFocus.z, sCustomCutsceneGeneric.focus.z + if_then_else(sCustomCutsceneGeneric.shake, math.random(-100, 100), 0), t)

    vec3f_set(gLakituState.pos, posX, posY, posZ)
    vec3f_set(gLakituState.focus, focX, focY, focZ)
end

function start_custom_cutscene_generic(posX, posY, posZ, focX, focY, focZ, time, shake, overrideCurrent)
    sCustomCutsceneGeneric.pos = { x = posX, y = posY, z = posZ }
    sCustomCutsceneGeneric.focus = { x = focX, y = focY, z = focZ }
    sCustomCutsceneGeneric.time = time
    sCustomCutsceneGeneric.shake = shake
    start_custom_cutscene(custom_cutscene_generic, overrideCurrent)
end

local function custom_cutscene_apparition_battle()
    camera_freeze()

    local a = sCustomCutsceneApparitionBattle.apparition
    if a ~= nil then
        vec3f_set(gLakituState.pos, a.oPosX + sins(a.oFaceAngleYaw) * (100 + (gCustomCutscene.timer * 8)), a.oPosY + (130 - (gCustomCutscene.timer * 2.5)), a.oPosZ + coss(a.oFaceAngleYaw) * (100 + (gCustomCutscene.timer * 8)))
        vec3f_set(gLakituState.focus, a.oPosX, a.oPosY + 130, a.oPosZ)
    end
end

--- @param apparition Object
function start_custom_cutscene_apparition_battle(apparition, overrideCurrent)
    sCustomCutsceneApparitionBattle.apparition = apparition
    start_custom_cutscene(custom_cutscene_apparition_battle, overrideCurrent)
end

function is_playing_custom_cutscene_apparition_battle()
    return gCustomCutscene.func == custom_cutscene_apparition_battle and gCustomCutscene.playing
end

local function custom_cutscene_betrayal()
    camera_freeze()

    --- @type MarioState
    local m = gMarioStates[0]

    --- @type Object
    local a = gCustomCutsceneBetrayal.apparition

    if m.actionState == 0 then
        local t = minf(gCustomCutscene.timer / 90, 1)
        local forward = { x = sins(a.oFaceAngleYaw) * 1000, y = 0, z = coss(a.oFaceAngleYaw) * 1000 }
        local posX = smooth_lerp(gCustomCutscene.prevCamPos.x, a.oPosX + forward.x, t)
        local posY = smooth_lerp(gCustomCutscene.prevCamPos.y, a.oPosY + 300, t)
        local posZ = smooth_lerp(gCustomCutscene.prevCamPos.z, a.oPosZ + forward.z, t)

        local focX = smooth_lerp(gCustomCutscene.prevCamFocus.x, a.oPosX, t)
        local focY = smooth_lerp(gCustomCutscene.prevCamFocus.y, a.oPosY + 100, t)
        local focZ = smooth_lerp(gCustomCutscene.prevCamFocus.z, a.oPosZ, t)

        vec3f_set(gLakituState.pos, posX, posY, posZ)
        vec3f_set(gLakituState.focus, focX, focY, focZ)
    elseif m.actionState == 1 then
        if obj_has_model_extended(a, E_MODEL_APPARITION) == 0 then
            play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
            obj_set_model_extended(a, E_MODEL_APPARITION)
        end

        local posX = a.oPosX - 200 + math.random(-5, 5)
        local posY = a.oPosY + 30 + math.random(-5, 5)
        local posZ = a.oPosZ + 450 + math.random(-5, 5)

        local focX = m.pos.x + math.random(-5, 5)
        local focY = lerp(a.oPosY + 100, m.pos.y + 100, 0.5) + math.random(-5, 5)
        local focZ = m.pos.z + math.random(-5, 5)

        vec3f_set(gLakituState.pos, posX, posY, posZ)
        vec3f_set(gLakituState.focus, focX, focY, focZ)

        if a.oAction ~= 1 then
            a.oAction = 1
            a.header.gfx.animInfo.animFrame = 0
        end
    elseif m.actionState == 2 then
        local posX = -10000
        local posY = a.oPosY + 500
        local posZ = lerp(m.pos.z, a.oPosZ, 0.5)

        local focX = posX + 1
        local focY = posY
        local focZ = posZ

        vec3f_set(gLakituState.pos, posX, posY, posZ)
        vec3f_copy(m.area.camera.pos, gLakituState.pos)
        vec3f_set(gLakituState.focus, focX, focY, focZ)
        vec3f_copy(m.area.camera.focus, gLakituState.focus)
    elseif m.actionState == 3 then
        local forward = { x = sins(a.oFaceAngleYaw) * 1000, y = 0, z = coss(a.oFaceAngleYaw) * 1000 }
        local t = minf(gCustomCutscene.timer / 150, 1)
        local posX = smooth_lerp(m.pos.x, a.oPosX, t) + forward.x
        local posY = smooth_lerp(m.pos.y + 700, a.oPosY + 100, t)
        local posZ = smooth_lerp(m.pos.z, a.oPosZ, t) + forward.z

        local focX = a.oPosX
        local focY = a.oPosY + 300
        local focZ = a.oPosZ

        vec3f_set(gLakituState.pos, posX, posY, posZ)
        vec3f_set(gLakituState.focus, focX, focY, focZ)
        if m.area.camera ~= nil then
            vec3f_copy(m.area.camera.pos, gLakituState.pos)
            vec3f_copy(m.area.camera.focus, gLakituState.focus)
        end
    elseif m.actionState == 4 then
        if gCustomCutscene.timer == 0 then
            flashAlpha = 255
        elseif gCustomCutscene.timer == 5 then
            obj_mark_for_deletion(get_npc_with_id(1))
            play_sound(SOUND_MENU_STAR_SOUND, m.marioObj.header.gfx.cameraToObject)
            play_sound(SOUND_GENERAL_VANISH_SFX, m.marioObj.header.gfx.cameraToObject)
            set_mario_action(m, ACT_IDLE, 0)
            audio_stream_stop(STREAM_SRIATS_SSELDNE)
            play_music(0, SEQUENCE_ARGS(8, SEQ_LEVEL_UNDERGROUND), 30)
            end_custom_cutscene()
        end
    end
end

function start_custom_cutscene_betrayal(apparition, overrideCurrent)
    gCustomCutsceneBetrayal.apparition = apparition
    gCustomCutsceneBetrayal.apparition.oFaceAngleYaw = gCustomCutsceneBetrayal.apparition.oMoveAngleYaw
    start_custom_cutscene(custom_cutscene_betrayal, overrideCurrent)
end

local function update()
    if not gCustomCutscene.playing then
        if camera_is_frozen() then
            camera_unfreeze()
        end
        return
    end

    if gCustomCutscene.func ~= nil then gCustomCutscene.func() end
    gCustomCutscene.timer = gCustomCutscene.timer + 1
    gMarioStates[0].freeze = 1
end

hook_event(HOOK_UPDATE, update)