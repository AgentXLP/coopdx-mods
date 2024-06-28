-- name: [PET] Propeller Fly Guy
-- description: [PET] Propeller Fly Guy\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a fly guy pet that behaves like the propeller blocks from New Super Mario Bros. Wii.\n\nTo use the Propeller Fly Guy, first spawn one through the pets menu, grab him and jump in the air and then press\n[\\#3040ff\\A\\#dcdcdc\\]. You will propel upwards and eventually begin to descend. To slow your descent, press [\\#3040ff\\A\\#dcdcdc\\] in rapid succession. To speed up your descent, hold down [\\#3040ff\\Z\\#dcdcdc\\].
-- pausable: true

if _G.wpets == nil then
    local first = false
    hook_event(HOOK_ON_LEVEL_INIT, function()
        if not first then
            first = true
            play_sound(SOUND_MENU_CAMERA_BUZZ, gGlobalSoundSource)
            djui_chat_message_create("\\#ffa0a0\\[PET] Propeller Fly Guy requires WiddlePets to be enabled.\nPlease rehost with it enabled.")
        end
    end)
    return
end

local SOUND_CUSTOM_FLY = audio_sample_load("fly.ogg")
local SOUND_CUSTOM_FALL = audio_sample_load("fall.ogg")
local SOUND_CUSTOM_SPIN = audio_sample_load("spin.ogg")
local SOUND_CUSTOM_DRILL = audio_sample_load("drill.ogg")

local E_MODEL_FLYGUY_PET = smlua_model_util_get_id("flyguy_pet_geo")

local ACT_PET_PROPEL = allocate_mario_action(ACT_GROUP_AIRBORNE | ACT_FLAG_AIR | ACT_FLAG_ATTACKING | ACT_FLAG_ALLOW_VERTICAL_WIND_ACTION)

local ID_PROPELLER_FLYGUY = _G.wpets.add_pet({
	name = "Propeller Fly Guy", credit = "wibblus, Agent X, Nintendo",
	description = "Propelling into the sky without a care in the world. Waaaow.",
	modelID = E_MODEL_FLYGUY_PET,
	scale = 0.8, yOffset = 0, flying = true
})
_G.wpets.set_pet_anims_wing(ID_PROPELLER_FLYGUY)
_G.wpets.set_pet_sounds(ID_PROPELLER_FLYGUY, {
	spawn = SOUND_OBJ_SNUFIT_SKEETER_DEATH,
	happy = SOUND_OBJ_SNUFIT_SKEETER_DEATH
})

local PET_PROPEL_HEIGHT = 60
local PET_PROPEL_FALL = -10
local PET_PROPEL_SPIN = 10
local PET_PROPEL_DRILL = -75

--- @param cond boolean
--- Human readable ternary operator
function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

--- @param m MarioState
local function act_pet_propel(m)
    if (m.marioObj.oInteractStatus & INT_STATUS_MARIO_DROP_OBJECT) ~= 0 then
        return drop_and_set_mario_action(m, ACT_FREEFALL, 0)
    end
    if (m.input & INPUT_B_PRESSED) ~= 0 then
        local pet = m.heldObj
        local ret = drop_and_set_mario_action(m, ACT_AIR_THROW, 0)
        pet.oFaceAngleYaw = m.faceAngle.y
        pet.oHeldState = HELD_THROWN
        return ret
    end

    if m.actionTimer == 0 then
        audio_sample_play(SOUND_CUSTOM_FLY, m.pos, 1)
    end

    set_character_animation(m, CHAR_ANIM_JUMP_WITH_LIGHT_OBJ)

    update_lava_boost_or_twirling(m)

    -- action state 0: the initial propel
    -- action state 1: the fall
    if m.actionState == 0 then
        m.twirlYaw = m.twirlYaw + 0x100 * m.vel.y
        if m.vel.y <= 0 then
            m.actionState = 1
        end
    else
        m.twirlYaw = m.twirlYaw + clamp(0x200 * math.abs(m.vel.y), 0, 0x2000)
        if m.actionTimer % 10 == 0 and m.vel.y >= PET_PROPEL_FALL then
            audio_sample_play(SOUND_CUSTOM_FALL, m.pos, 1)
            m.actionArg = 0
        end

        if (m.input & INPUT_A_PRESSED) ~= 0 and (m.input & INPUT_Z_DOWN) == 0 and m.vel.y <= PET_PROPEL_FALL then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
            audio_sample_play(SOUND_CUSTOM_SPIN, m.pos, 1)
            m.vel.y = m.vel.y + PET_PROPEL_SPIN
        end
    end

    local step = perform_air_step(m, 0)
    if step == AIR_STEP_LANDED then
        set_mario_action(m, ACT_HOLD_WALKING, 0)
    elseif step == AIR_STEP_HIT_WALL then
        mario_bonk_reflection(m, 0)
    elseif step == AIR_STEP_HIT_LAVA_WALL then
        lava_boost_on_wall(m)
    end

    m.marioObj.header.gfx.angle.y = m.twirlYaw
    m.peakHeight = m.pos.y
    m.actionTimer = m.actionTimer + 1
    return 0
end

--- @param m MarioState
local function act_pet_propel_gravity(m)
    if m.actionState == 0 then
        m.vel.y = m.vel.y - 1
    else
        m.vel.y = clampf(m.vel.y - 2, if_then_else((m.input & INPUT_Z_DOWN) ~= 0, PET_PROPEL_DRILL, PET_PROPEL_FALL), if_then_else(m.vel.y > 0, 15, 0))
        if m.vel.y < PET_PROPEL_FALL then
            set_mario_particle_flags(m, PARTICLE_DUST, false)
            if m.actionArg == 0 then
                audio_sample_play(SOUND_CUSTOM_DRILL, m.pos, 1)
                m.actionArg = 1
            end
        end
    end
end

--- @param m MarioState
local function mario_update(m)
    if m.heldObj == nil then return end

    if obj_has_model_extended(m.heldObj, E_MODEL_FLYGUY_PET) ~= 0 and (m.action == ACT_HOLD_JUMP or m.action == ACT_HOLD_FREEFALL or m.action == ACT_HOLD_WATER_JUMP) and (m.input & INPUT_A_PRESSED) ~= 0 and m.vel.y <= 0 then
        set_mario_action(m, ACT_PET_PROPEL, 0)
        spawn_mist_particles()
        if m.playerIndex == 0 then
            set_camera_shake_from_hit(SHAKE_POS_SMALL)
        end
        m.vel.y = PET_PROPEL_HEIGHT
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

hook_mario_action(ACT_PET_PROPEL, { every_frame = act_pet_propel, gravity = act_pet_propel_gravity })