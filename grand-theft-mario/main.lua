-- name: Grand Theft Mario
-- description: Grand Theft Mario / Gun Mod\nBy: \\#ff7f00\\Agent X\\#ffffff\\\n\nThis mod adds guns to sm64ex-coop. You can give yourself a gun and shoot it by pressing [\\#3040ff\\Y\\#ffffff\\].

E_MODEL_GUN = smlua_model_util_get_id("gun_geo")
gGlobalSyncTable.dmg = 3
gGlobalSyncTable.maxAmmo = 20
gGlobalSyncTable.infAmmo = true
gGlobalSyncTable.warpAmmo = true
gun = nil

reloadTime = 90
reloadTimer = 90
shootTime = 8
shootTimer = 8
function mario_update_local(m)
    if gun ~= nil then
        if m.action ~= ACT_FLYING and (m.action & ACT_FLAG_SWIMMING) == 0 then
            gun.oPosX = get_hand_foot_pos_x(m, 0)
            gun.oPosY = get_hand_foot_pos_y(m, 0)
            gun.oPosZ = get_hand_foot_pos_z(m, 0)
        else
            gun.oPosX = m.pos.x
            gun.oPosY = m.pos.y
            gun.oPosZ = m.pos.z
        end
        gun.oFaceAnglePitch = 0
        gun.oFaceAngleYaw = m.faceAngle.y
        gun.oFaceAngleRoll = 0

        if m.health == 0xff or m.action == ACT_IN_CANNON or m.action == ACT_SLEEPING then -- dead
            despawn_gun()
            return
        end

        if shootTimer ~= shootTime then
            shootTimer = shootTimer + 1
        end

        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and shootTimer == shootTime then
            if gPlayerSyncTable[0].ammo > 0 then
                play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, m.marioObj.header.gfx.cameraToObject) -- works rarely

                bullet = spawn_sync_object(
                    id_bhvBullet,
                    E_MODEL_YELLOW_COIN,
                    m.pos.x, m.pos.y + 50, m.pos.z,
                    nil
                )
                gPlayerSyncTable[0].ammo = gPlayerSyncTable[0].ammo - 1
                shootTimer = 0
            else
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        end

        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and m.action == ACT_FLYING and shootTimer + 10 == shootTime + 10 then
            if gPlayerSyncTable[0].ammo >= 3 then
                play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, m.marioObj.header.gfx.cameraToObject) -- works rarely
                
                spawn_sync_object(
                    id_bhvBobomb,
                    E_MODEL_BLACK_BOBOMB,
                    m.pos.x, m.pos.y, m.pos.z,
                    function (obj)
                        obj.oAction = 1
                        obj.oFaceAnglePitch = 0
                        obj.oFaceAngleYaw = 0
                        obj.oFaceAngleRoll = 0
                    end
                )
                gPlayerSyncTable[0].ammo = gPlayerSyncTable[0].ammo - 3
                shootTimer = 0
            end
        end 
    else
        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
            if m.health ~= 0xff and m.action ~= ACT_IN_CANNON and m.action ~= ACT_SLEEPING then
                gun = spawn_sync_object(
                    id_bhvGun,
                    E_MODEL_GUN,
                    get_hand_foot_pos_x(m, 0), get_hand_foot_pos_y(m, 0), get_hand_foot_pos_z(m, 0),
                    nil
                )
            end
        end
    end

    if gPlayerSyncTable[0].ammo <= 0 then
        gPlayerSyncTable[0].ammo = 0
        if gGlobalSyncTable.infAmmo == false then
            return
        end
        reloadTimer = reloadTimer - 1
        if reloadTimer == 0 then
            gPlayerSyncTable[0].ammo = gGlobalSyncTable.maxAmmo
            play_sound(SOUND_MENU_POWER_METER, m.marioObj.header.gfx.cameraToObject)
            reloadTimer = reloadTime
        end
    end
end

function mario_update(m)
    if m.playerIndex == 0 then
        mario_update_local(m)
    end
end

function despawn_gun()
    if gun ~= nil then
        obj_mark_for_deletion(gun)
        gun = nil 
    end
end

function on_interact(m, obj, type, value)
    if type == INTERACT_COIN and gPlayerSyncTable[m.playerIndex].ammo + obj.oDamageOrCoinValue <= gGlobalSyncTable.maxAmmo then
        gPlayerSyncTable[m.playerIndex].ammo = gPlayerSyncTable[m.playerIndex].ammo + obj.oDamageOrCoinValue
    end
end

function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].ammo = 20
end

function on_warp()
    despawn_gun()
    if gGlobalSyncTable.warpAmmo == true then
        gPlayerSyncTable[0].ammo = gGlobalSyncTable.maxAmmo 
    end
end

-----------
-- hooks --
-----------

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_WARP, on_warp)

if gServerSettings.playerInteractions ~= 2 then
    djui_popup_create("\\#ffff00\\It is recommended you turn on friendly fire on to use the gun mod,", 1)
end