-- name: Grand Theft Mario
-- description: Grand Theft Mario v1.1.2\nBy: \\#ff7f00\\Agent X\\#ffffff\\\n\nThis mod adds guns to sm64ex-coop. You can give yourself a gun and shoot it by pressing [\\#3040ff\\Y\\#ffffff\\] and swap between the USP and the magnum with DPad Up.

E_MODEL_CORPSE = smlua_model_util_get_id("skeleton_geo")

gGlobalSyncTable.infAmmo = true
gGlobalSyncTable.warpAmmo = true

gGlobalSyncTable.bossTolerance = 3 -- times a boss needs to be shot before taking damage, networking it would be good I think
gun = nil

-- skeleton spawning on death
local corpse = nil
local corpseTime  = 100
local corpseTimer = 100

function get_ammo(m)
    if gPlayerSyncTable[m.playerIndex].gun == GUN_USP then
        return gPlayerSyncTable[m.playerIndex].ammoUSP
    elseif gPlayerSyncTable[m.playerIndex].gun == GUN_MAGNUM then
        return gPlayerSyncTable[m.playerIndex].ammoMagnum
    end
end
function set_ammo(m, value)
    if gPlayerSyncTable[m.playerIndex].gun == GUN_USP then
        gPlayerSyncTable[m.playerIndex].ammoUSP = value
    elseif gPlayerSyncTable[m.playerIndex].gun == GUN_MAGNUM then
        gPlayerSyncTable[m.playerIndex].ammoMagnum = value
    end
end

reloadTimer = 75 -- default values
shootTimer = 6
local localGun = gPlayerSyncTable[0].gun
function mario_update_local(m)
    localGun = gPlayerSyncTable[0].gun
    if m.health == 0xff and corpse == nil then
        if corpseTimer > 0 then
            corpseTimer = corpseTimer - 1
        else
            corpseTimer = corpseTime
            corpse = spawn_sync_object(
                id_bhvBreakableBoxSmall,
                E_MODEL_CORPSE,
                m.pos.x, m.pos.y, m.pos.z,
                nil
            )
        end
    end

    if gun ~= nil then
        if m.health <= 0xff or m.action == ACT_IN_CANNON or m.action == ACT_DISAPPEARED then
            despawn_gun()
            return
        end

        if shootTimer ~= gunTable[localGun].shootTime then
            shootTimer = shootTimer + 1
        end

        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and shootTimer == gunTable[localGun].shootTime then
            if get_ammo(m) > 0 then
                spawn_sync_object(
                    id_bhvBullet,
                    E_MODEL_YELLOW_COIN,
                    m.pos.x, m.pos.y + 50, m.pos.z,
                    function (o)
                        o.oDamageOrCoinValue = gunTable[localGun].dmg
                    end
                )

                play_sound(gunTable[localGun].sound, m.marioObj.header.gfx.cameraToObject)

                set_ammo(m, get_ammo(m) - 1)
                gPlayerSyncTable[0].shotsFired = gPlayerSyncTable[0].shotsFired + 1
                network_player_set_description(gNetworkPlayers[0], tostring(gPlayerSyncTable[0].shotsFired) .. " shots", 255, 255, 255, 255)
                shootTimer = 0
            else
                play_sound(SOUND_MENU_CAMERA_BUZZ, m.marioObj.header.gfx.cameraToObject)
            end
        end

        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and shootTimer + 10 == gunTable[localGun].shootTime + 10 then
            if m.action == ACT_FLYING then
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
                gPlayerSyncTable[0].shotsFired = gPlayerSyncTable[0].shotsFired + 3
                network_player_set_description(gNetworkPlayers[0], tostring(gPlayerSyncTable[0].shotsFired) .. " shots", 255, 255, 255, 255)
                shootTimer = 0
            else
                if is_gordon(m) and (m.controller.buttonDown & R_JPAD) ~= 0 and shootTimer + 10 == gunTable[localGun] + 10 then
                    spawn_sync_object(
                        id_bhvBobomb,
                        E_MODEL_BLACK_BOBOMB,
                        m.pos.x + m.vel.x, m.pos.y + m.vel.y, m.pos.z + m.vel.z,
                        nil
                    )
                    network_player_set_description(gNetworkPlayers[0], tostring(gPlayerSyncTable[0].shotsFired) .. " shots", 255, 255, 255, 255)
                    shootTimer = 0
                end
            end
        end

        if (m.controller.buttonPressed & U_JPAD) ~= 0 then
            if gPlayerSyncTable[m.playerIndex].gun == GUN_USP then -- society if gPlayerSyncTable[m.playerIndex].gun == GUN_USP ? GUN_MAGNUM : GUN_USP
                gun_change(m, GUN_MAGNUM)
            else
                gun_change(m, GUN_USP)
            end
        end
    else
        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 then
            if m.health ~= 0xff and m.action ~= ACT_IN_CANNON then
                gun = spawn_sync_object(
                    id_bhvGun,
                    gunTable[localGun].model,
                    get_hand_foot_pos_x(m, 0), get_hand_foot_pos_y(m, 0), get_hand_foot_pos_z(m, 0),
                    function (obj)
                        obj.oGunOwner = gNetworkPlayers[0].globalIndex
                    end
                )
            end
        end
    end

    if get_ammo(m) <= 0 then
        if gGlobalSyncTable.infAmmo == false then
            return
        end
        set_ammo(m, 0)
        reloadTimer = reloadTimer - 1
        if reloadTimer == 0 then
            set_ammo(m, gunTable[localGun].maxAmmo)
            play_sound(SOUND_MENU_POWER_METER, m.marioObj.header.gfx.cameraToObject)
            reloadTimer = gGlobalSyncTable.reloadTime
        end
    end

    -- failsafe, gordon related
    if m.character.type ~= 1 then
		gPlayerSyncTable[0].modelId = nil
	end
end

function mario_update(m)
    if m.playerIndex == 0 then
        mario_update_local(m)
    end

    if is_gordon(m) then
        obj_set_model_extended(m.marioObj, E_MODEL_GORDON)
    end
end

function is_gordon(m)
    return gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_GORDON
end

function despawn_gun()
    if gun ~= nil then
        obj_mark_for_deletion(gun)
        gun = nil 
    end
end

function on_interact(m, obj, type, value)
    if type == INTERACT_COIN and get_ammo(m) + obj.oDamageOrCoinValue <= gunTable[localGun].maxAmmo then
        set_ammo(m, get_ammo(m) + obj.oDamageOrCoinValue)
    end
end

function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].gun = GUN_USP

    gPlayerSyncTable[m.playerIndex].ammoUSP = gunTable[GUN_USP].maxAmmo
    gPlayerSyncTable[m.playerIndex].ammoMagnum = gunTable[GUN_MAGNUM].maxAmmo
    
    reloadTimer = gunTable[GUN_USP].reloadTime
    shootTimer = gunTable[GUN_USP].shootTime

    gPlayerSyncTable[m.playerIndex].shotsFired = 0
end

function gun_change(m, new)
    if gun == nil then
        return
    end
    gPlayerSyncTable[m.playerIndex].gun = new
    localGun = new
    reloadTimer = gunTable[gPlayerSyncTable[m.playerIndex].gun].reloadTime
    shootTimer = gunTable[gPlayerSyncTable[m.playerIndex].gun].shootTime

    obj_mark_for_deletion(gun)
    gun = spawn_sync_object(
        id_bhvGun,
        gunTable[localGun].model,
        get_hand_foot_pos_x(m, 0), get_hand_foot_pos_y(m, 0), get_hand_foot_pos_z(m, 0),
        function (obj)
            obj.oGunOwner = gNetworkPlayers[0].globalIndex
        end
    )
end

function on_warp() -- if using Dynos warps this isn't called
    despawn_gun()
    if gGlobalSyncTable.warpAmmo == true then
        set_ammo(gMarioStates[0], gunTable[localGun].maxAmmo)
    end
    corpse = nil
end


function on_hud_render()
    if gun == nil then
        return
    end

    -- set text and scale
    local text = tostring(get_ammo(gMarioStates[0])) .. "/" .. tostring(gunTable[localGun].maxAmmo)

    -- render to native screen space, with the MENU font
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_HUD)

    local x = 10
    local y = djui_hud_get_screen_height() - 35

    -- set color and render
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("AMMO", x, y - 20, 1)
    djui_hud_print_text(text, x, y, 1)
end

-----------
-- hooks --
-----------

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)

if gServerSettings.playerInteractions ~= 2 then
    djui_popup_create("\\#ffff00\\It is recommended you turn on friendly fire on to use the gun mod.", 2)
end
