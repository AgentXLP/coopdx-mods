-- name: Gun Mod
-- incompatible: weapon
-- description: Gun Mod v2.0.1\nBy \\#ff7f00\\Agent X\\#ffffff\\\n\nThis mod adds guns to sm64ex-coop. You can give yourself a gun and shoot it by pressing [\\#3040ff\\Y\\#ffffff\\] and swap between the PISTOL and the magnum with DPad Up.

sPlayerFirstPerson = { enabled = false, freecam = camera_config_is_free_cam_enabled(), pitch = 0, yaw = 0 }

LEVEL_BM = LEVEL_VCUTM

function in_range(v, min, max)
    if v > max or v < min then return true end
    return false
end

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

function warp(level, area)
    warp_to_level(level, area, 1)
    on_warp()
end

E_MODEL_CORPSE = smlua_model_util_get_id("skeleton_geo")

reloadTimer = 75 -- default value
shootTimer = 6 -- default value
local localWeapon = gPlayerSyncTable[0].weapon

--- @param m MarioState
function mario_update_local(m)
    localWeapon = gPlayerSyncTable[0].weapon
    if showTitle and gNetworkPlayers[0].currLevelNum == LEVEL_BM then return end

    if gun ~= nil then
        if m.health <= 0xff or m.action == ACT_IN_CANNON or m.action == ACT_DISAPPEARED then
            despawn_weapon()
            return
        end

        if shootTimer ~= weaponTable[localWeapon].shootTime then
            shootTimer = shootTimer + 1
        end

        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and weaponTable[localWeapon].call ~= nil then
            weaponTable[localWeapon].call()
        end
        if weaponTable[localWeapon].loop ~= nil then weaponTable[localWeapon].loop() end

        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and weaponTable[gPlayerSyncTable[0].weapon].gun and shootTimer + 10 == weaponTable[localWeapon].shootTime + 10 then
            if m.action == ACT_FLYING then
                spawn_sync_object(
                    id_bhvBobomb,
                    E_MODEL_BLACK_BOBOMB,
                    m.pos.x, m.pos.y, m.pos.z,
                    --- @param o Object
                    function (o)
                        o.oAction = 1
                        o.oFaceAnglePitch = 0
                        o.oFaceAngleYaw = 0
                        o.oFaceAngleRoll = 0
                    end
                )

                gPlayerSyncTable[0].shotsFired = gPlayerSyncTable[0].shotsFired + 3
                shootTimer = 0
            else
                if is_gordon(m) and (m.controller.buttonDown & R_JPAD) ~= 0 and shootTimer + 10 == weaponTable[localWeapon] + 10 then
                    spawn_sync_object(
                        id_bhvBobomb,
                        E_MODEL_BLACK_BOBOMB,
                        m.pos.x + m.vel.x, m.pos.y + m.vel.y, m.pos.z + m.vel.z,
                        nil
                    )
                    shootTimer = 0
                end
            end
        end

        if (m.controller.buttonPressed & U_JPAD) ~= 0 then
            if gPlayerSyncTable[0].weapon < weaponCount - 1 then
                weapon_change(m, gPlayerSyncTable[0].weapon + 1)
            else
                weapon_change(m, 0)
            end
        end

        if (m.controller.buttonPressed & D_JPAD) ~= 0 and weaponTable[localWeapon].gun then
            on_reload_command()
        end
    else
        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and gNetworkPlayers[0].currAreaSyncValid then
            if m.health > 0xff and m.action ~= ACT_IN_CANNON and m.action ~= ACT_DISAPPEARED then
                spawn_weapon()
            end
        end
    end

    if weaponTable[localWeapon].gun and get_ammo() ~= nil then
        if get_ammo() <= 0 then
            if gGlobalSyncTable.infAmmo == false then
                return
            end
            set_ammo(0)
            reloadTimer = reloadTimer - 1
            if reloadTimer == 0 then
                set_ammo(weaponTable[localWeapon].maxAmmo)
                audio_sample_play(weaponTable[localWeapon].reloadSound, m.pos, 0.75)
                reloadTimer = weaponTable[gPlayerSyncTable[0].weapon].reloadTime
            end
        end
    end
end

--- @param m MarioState
function mario_update(m)
    if m.playerIndex == 0 then
        mario_update_local(m)
    end

    network_player_set_description(gNetworkPlayers[m.playerIndex], tostring(gPlayerSyncTable[m.playerIndex].shotsFired) .. " shots", 255, 255, 255, 255)

    if is_gordon(m) then
        obj_set_model_extended(m.marioObj, E_MODEL_GORDON)
    end
end

--- @param m MarioState
function is_gordon(m)
    if m.playerIndex == 0 and sPlayerFirstPerson.enabled then return false end
    return gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_GORDON
end

--- @param m MarioState
--- @param o Object
function on_interact(m, o, type, value)
    if type == INTERACT_COIN and get_ammo() + o.oDamageOrCoinValue <= weaponTable[localWeapon].maxAmmo then
        set_ammo(get_ammo() + o.oDamageOrCoinValue)
    end
end
--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].weapon = WEAPON_PISTOL

    for k, v in pairs(weaponTable) do
        if weaponTable[k].gun then
            gPlayerSyncTable[m.playerIndex]["ammo" .. weaponTable[k].name] = weaponTable[k].maxAmmo 
        end
    end

    reloadTimer = weaponTable[WEAPON_PISTOL].reloadTime
    shootTimer = weaponTable[WEAPON_PISTOL].shootTime

    gPlayerSyncTable[m.playerIndex].shotsFired = 0

    -- first person
    gPlayerSyncTable[m.playerIndex].metalCap = false
end

function on_warp()
    if gNetworkPlayers[0].currLevelNum == LEVEL_BM then gMarioStates[0].health = 0x880 end -- fail safe
    despawn_weapon()
    if gGlobalSyncTable.warpAmmo then
        set_ammo(weaponTable[localWeapon].maxAmmo)
    end

    if gNetworkPlayers[0].currLevelNum == LEVEL_BM then
        local m = gMarioStates[0]
        m.flags = m.flags & ~(MARIO_VANISH_CAP | MARIO_METAL_CAP | MARIO_WING_CAP)
        if (m.flags & (MARIO_NORMAL_CAP | MARIO_VANISH_CAP | MARIO_METAL_CAP | MARIO_WING_CAP)) == 0 then
            m.flags = m.flags ~MARIO_CAP_ON_HEAD
        end
        m.capTimer = 0
        stop_cap_music()
        if gNetworkPlayers[0].currAreaIndex == 1 then
            showTitle = true
            play_sound(SOUND_GENERAL_LOUD_POUND2, gMarioStates[0].marioObj.header.gfx.cameraToObject) -- door closing kind of effect
        end
    end
end

function on_sync_valid()
    local m = gMarioStates[0]
    if m.health > 0xff and m.action ~= ACT_IN_CANNON and m.action ~= ACT_DISAPPEARED then
        spawn_weapon()
        -- audio_sample_play(weaponTable[WEAPON_PISTOL].reloadSound, m.pos, 0.75)
    end
end

--- @param m MarioState
SOUND_CUSTOM_DEATH = audio_sample_load("death.mp3")
function on_death(m)
    if m.playerIndex == 0 and m.floor.type ~= SURFACE_DEATH_PLANE then
        spawn_sync_object(
            id_bhvBreakableBoxSmall,
            E_MODEL_CORPSE,
            m.pos.x, m.pos.y, m.pos.z,
            nil
        )

        audio_sample_play(SOUND_CUSTOM_DEATH, m.pos, 1)
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_SYNC_VALID, on_sync_valid)
hook_event(HOOK_ON_DEATH, on_death)

smlua_text_utils_secret_star_replace(COURSE_VCUTM, "   BLACK MESA")

gServerSettings.playerInteractions = 2
gServerSettings.bubbleDeath = 0

for mod in pairs(gActiveMods) do
    local m = gMarioStates[0]
    if gActiveMods[mod].name == "MariO" then
        play_sound(SOUND_MENU_MESSAGE_APPEAR, m.marioObj.header.gfx.cameraToObject)
        djui_chat_message_create("\\#9ac4f7\\Agent\\#ff7f00\\X: \\#ffffff\\I shoud collab with Peachy sometime.")
    end
end
-- gLevelValues.entryLevel = LEVEL_VCUTM