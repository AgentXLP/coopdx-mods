-- name: Hats
-- description: Hats\nBy \\#dd7032\\CosmicMan08\\#dcdcdc\\ and \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds 15 hats to sm64ex-coop being a top hat, crown, halo, cape, sonic hair, dr headband, raccoon ears and tail, chain chomp, artisan, bone brim, slumber, sign, pipe and water bomb.\n\nUse /hat [0-15] to select your hat, 0\nbeing none.

define_custom_obj_fields({
    oHatOwner = 'u32',
})

local HAT_NONE = 0
local HAT_TOP_HAT = 1
local HAT_CROWN = 2
local HAT_HALO = 3
local HAT_CAPE = 4
local HAT_SONIC_HAIR = 5
local HAT_DR_HEADBAND = 6
local HAT_RACCOON = 7
local HAT_CHOMPER = 8
local HAT_ARTISAN = 9
local HAT_BONE_BRIM = 10
local HAT_HEADCRAB = 11
local HAT_SLUMBER = 12
local HAT_SIGN = 13
local HAT_PIPE = 14
local HAT_WATER_BOMB = 15

--- @class Hat
--- @field public model ModelExtendedId
--- @field public cap boolean

--- @type Hat[]
local gHatList = {
    [HAT_TOP_HAT] =     { model = smlua_model_util_get_id("tophat_geo"),     cap = false },
    [HAT_CROWN] =       { model = smlua_model_util_get_id("crown_geo"),      cap = false },
    [HAT_HALO] =        { model = smlua_model_util_get_id("halo_geo"),       cap = false },
    [HAT_CAPE] =        { model = smlua_model_util_get_id("cape_geo"),       cap = true  },
    [HAT_SONIC_HAIR] =  { model = smlua_model_util_get_id("sonichair_geo"),  cap = false },
    [HAT_DR_HEADBAND] = { model = smlua_model_util_get_id("drheadband_geo"), cap = false },
    [HAT_RACCOON] =     { model = smlua_model_util_get_id("raccoon_geo"),    cap = true  },
    [HAT_CHOMPER] =     { model = smlua_model_util_get_id("chomper_geo"),    cap = false },
    [HAT_ARTISAN] =     { model = smlua_model_util_get_id("artisan_geo"),    cap = false },
    [HAT_BONE_BRIM] =   { model = smlua_model_util_get_id("bonebrim_geo"),   cap = false },
    [HAT_HEADCRAB] =    { model = smlua_model_util_get_id("headcrab_geo"),   cap = false },
    [HAT_SLUMBER] =     { model = smlua_model_util_get_id("slumber_geo"),    cap = true  },
    [HAT_SIGN] =        { model = E_MODEL_WOODEN_SIGNPOST,                   cap = true  },
    [HAT_PIPE] =        { model = E_MODEL_BITS_WARP_PIPE,                    cap = true  },
    [HAT_WATER_BOMB] =  { model = E_MODEL_WATER_BOMB,                        cap = true  }
}

--- @param m MarioState
local function active_player(m)
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

--- @param o Object
local function bhv_hat_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(1)

    o.hitboxRadius = 0
    o.hitboxHeight = 0

    cur_obj_hide()
end

--- @param o Object
local function bhv_hat_loop(o)
    local np = network_player_from_global_index(o.oHatOwner)
    if np == nil or gPlayerSyncTable[np.localIndex].hat == HAT_NONE then
        obj_mark_for_deletion(o)
        return
    end

    local m = gMarioStates[np.localIndex]
    if active_player(m) == 0 then
        obj_mark_for_deletion(o)
        return
    end

    if m.marioBodyState.updateTorsoTime == gMarioStates[0].marioBodyState.updateTorsoTime and m.action ~= ACT_DISAPPEARED and m.action ~= ACT_IN_CANNON then
        if (m.action & ACT_FLAG_ON_POLE) == 0 then
            if gPlayerSyncTable[m.playerIndex].hat ~= HAT_PIPE then
                o.oPosX = m.marioBodyState.headPos.x + m.vel.x
                o.oPosY = m.marioBodyState.headPos.y + m.vel.y
                o.oPosZ = m.marioBodyState.headPos.z + m.vel.z
            else
                vec3f_to_object_pos(o, m.pos)
            end
        else
            vec3f_to_object_pos(o, m.marioBodyState.headPos)
        end
        o.oFaceAnglePitch = m.marioObj.header.gfx.angle.x + (m.marioBodyState.torsoAngle.x * 0.5)
        o.oFaceAngleYaw = m.marioObj.header.gfx.angle.y + (m.marioBodyState.torsoAngle.y * 0.5)
        o.oFaceAngleRoll = m.marioObj.header.gfx.angle.z + (m.marioBodyState.torsoAngle.z * 0.5)
        cur_obj_unhide()
    else
        vec3f_to_object_pos(o, m.pos)
        cur_obj_hide()
    end

    obj_set_model_extended(o, gHatList[gPlayerSyncTable[m.playerIndex].hat].model)
end

local id_bhvHat = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_hat_init, bhv_hat_loop)

--- @param m MarioState
local function mario_update(m)
    if gPlayerSyncTable[m.playerIndex].hat == HAT_NONE or active_player(m) == 0 then return end

    if gPlayerSyncTable[m.playerIndex].hat ~= HAT_NONE and not gHatList[gPlayerSyncTable[m.playerIndex].hat].cap then
        m.marioBodyState.capState = MARIO_HAS_DEFAULT_CAP_OFF
    end

    local spawned = false
    local hat = obj_get_first_with_behavior_id(id_bhvHat)
    while hat ~= nil do
        if hat.oHatOwner == gNetworkPlayers[m.playerIndex].globalIndex then
            spawned = true
            break
        end
        hat = obj_get_next_with_same_behavior_id(hat)
    end
    if not spawned then
        spawn_non_sync_object(
            id_bhvHat,
            E_MODEL_NONE,
            m.pos.x, m.pos.y, m.pos.z,
            --- @param o Object
            function(o)
                o.oHatOwner = gNetworkPlayers[m.playerIndex].globalIndex
            end
        )
        spawned = true
    end
end


local function on_hat_command(msg)
    if msg == "0" then
        gPlayerSyncTable[0].hat = HAT_NONE
    else
        local names = {
            none = HAT_NONE,
            top_hat = HAT_TOP_HAT,
            crown = HAT_CROWN,
            halo = HAT_HALO,
            cape = HAT_CAPE,
            sonic_hair = HAT_SONIC_HAIR,
            dr_headband = HAT_DR_HEADBAND,
            raccoon = HAT_RACCOON,
            chomper = HAT_CHOMPER,
            artisan = HAT_ARTISAN,
            bone_brim = HAT_BONE_BRIM,
            headcrab = HAT_HEADCRAB,
            slumber = HAT_SLUMBER,
            sign = HAT_SIGN,
            pipe = HAT_PIPE,
            water_bomb = HAT_WATER_BOMB
        }

        local number = tonumber(msg)
        if names[msg:lower()] ~= nil then
            gPlayerSyncTable[0].hat = names[msg:lower()]
        elseif number == nil or number < 0 or number > 15 then
            djui_chat_message_create("\\#ff0000\\Failed to set hat to " .. msg)
        else
            gPlayerSyncTable[0].hat = number
        end
    end
    djui_chat_message_create("Hat set to " .. gPlayerSyncTable[0].hat)
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)

hook_chat_command("hat", "[0-" .. #gHatList .. "] to select your hat, 0 being none", on_hat_command)

for i = 0, (MAX_PLAYERS - 1) do
    gPlayerSyncTable[i].hat = HAT_NONE
end