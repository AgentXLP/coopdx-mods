-- name: Grand Theft Mario
-- description: Grand Theft Mario v2.0\nBy: \\#ff7f00\\Agent X\\#ffffff\\\n\nThis mod adds guns to sm64ex-coop. You can give yourself a gun and shoot it by pressing [\\#3040ff\\Y\\#ffffff\\] and swap between the PISTOL and the magnum with DPad Up.

_G.switch = function(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

function in_range(v, min, max)
    if v > max or v < min then return true end
    return false
end

E_MODEL_CORPSE = smlua_model_util_get_id("skeleton_geo")

gGlobalSyncTable.infAmmo = true
gGlobalSyncTable.warpAmmo = true

gGlobalSyncTable.bossTolerance = 5 -- times a boss needs to be shot before taking damage, networking it would be good I think
gun = nil

syncing = false -- gets set to true when syncing becomes validated

-- skeleton spawning on death
local corpse = nil
local corpseTime  = 100
local corpseTimer = 100

--- @param m MarioState
function get_ammo(m)
    if gPlayerSyncTable[m.playerIndex].gun == GUN_PISTOL then
        return gPlayerSyncTable[m.playerIndex].ammoPistol
    elseif gPlayerSyncTable[m.playerIndex].gun == GUN_MAGNUM then
        return gPlayerSyncTable[m.playerIndex].ammoMagnum
    end
end

--- @param m MarioState
function set_ammo(m, value)
    if gPlayerSyncTable[m.playerIndex].gun == GUN_PISTOL then
        gPlayerSyncTable[m.playerIndex].ammoPistol = value
    elseif gPlayerSyncTable[m.playerIndex].gun == GUN_MAGNUM then
        gPlayerSyncTable[m.playerIndex].ammoMagnum = value
    end
end

function warp(level, area)
    warp_to_level(level, area, 1)
    on_warp()
end

local totwcTimer = 0
function totwc_warp()
    if totwcTimer == 0 then
        play_transition(0x01, 30, 255, 255, 255)
        play_sound(SOUND_MENU_STAR_SOUND, gMarioStates[0].marioObj.header.gfx.cameraToObject) 
    end
    if totwcTimer == 30 then
        warp(LEVEL_TOTWC, 1)
    else
        totwcTimer = totwcTimer + 1
    end
end

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

reloadTimer = 75 -- default value
shootTimer = 6 -- default value
local localGun = gPlayerSyncTable[0].gun

--- @param m MarioState
function mario_update_local(m)
    localGun = gPlayerSyncTable[0].gun
    if showTitle and gNetworkPlayers[0].currLevelNum == LEVEL_SA then return end

    if m.health <= 0xff and corpse == nil then
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
                    gunTable[localGun].bullet,
                    m.pos.x, m.pos.y + 60, m.pos.z,
                    --- @param o Object
                    function (o)
                        o.oDamageOrCoinValue = gunTable[localGun].dmg
                        o.header.gfx.scale.x = gunTable[localGun].bulletScale
                        o.header.gfx.scale.y = gunTable[localGun].bulletScale
                        o.header.gfx.scale.z = gunTable[localGun].bulletScale

                        o.oBulletOwner = gNetworkPlayers[0].globalIndex

                        if firstPerson or (m.input & INPUT_FIRST_PERSON) ~= 0 then
                            o.oGraphYOffset = 50

                            -- thanks PeachyPeach.
                            local dx = m.area.camera.focus.x - m.area.camera.pos.x
                            local dy = m.area.camera.focus.y - m.area.camera.pos.y
                            local dz = m.area.camera.focus.z - m.area.camera.pos.z
                            local dv = math.sqrt(dx * dx + dy * dy + dz * dz)
                            o.oVelX = GUN_SHOOT_SPEED * (dx / dv)
                            o.oVelY = GUN_SHOOT_SPEED * (dy / dv)
                            o.oVelZ = GUN_SHOOT_SPEED * (dz / dv)
                            o.oPosX = m.pos.x + (o.oVelX / GUN_SHOOT_SPEED)
                            o.oPosY = m.pos.y + 60 + (o.oVelY / GUN_SHOOT_SPEED)
                            o.oPosZ = m.pos.z + (o.oVelZ / GUN_SHOOT_SPEED)
                        end
                    end
                )

                set_ammo(m, get_ammo(m) - 1)
                gPlayerSyncTable[0].shotsFired = gPlayerSyncTable[0].shotsFired + 1
                shootTimer = 0
            else
                audio_sample_play(SOUND_CUSTOM_DRYFIRE, m.pos, 0.5)
            end
        end

        if (m.controller.buttonPressed & B_BUTTON) ~= 0 and shootTimer + 10 == gunTable[localGun].shootTime + 10 then
            if m.action == ACT_FLYING then
                spawn_sync_object(
                    id_bhvBobomb,
                    E_MODEL_BLACK_BOBOMB,
                    m.pos.x, m.pos.y, m.pos.z,
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
                if is_gordon(m) and (m.controller.buttonDown & R_JPAD) ~= 0 and shootTimer + 10 == gunTable[localGun] + 10 then
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
            if gPlayerSyncTable[m.playerIndex].gun == GUN_PISTOL then -- society if gPlayerSyncTable[m.playerIndex].gun == GUN_PISTOL ? GUN_MAGNUM : GUN_PISTOL
                gun_change(m, GUN_MAGNUM)
            else
                gun_change(m, GUN_PISTOL)
            end
        end

        if (m.controller.buttonPressed & D_JPAD) ~= 0 then
            on_reload_command()
        end
    else
        if (m.controller.buttonPressed & Y_BUTTON) ~= 0 and syncing then
            if m.health > 0xff and m.action ~= ACT_IN_CANNON and m.action ~= ACT_DISAPPEARED then
                spawn_gun()
                if arm == nil and firstPerson then
                    spawn_arm()
                end
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
            audio_sample_play(gunTable[localGun].reloadSound, m.pos, 0.75)
            reloadTimer = gunTable[gPlayerSyncTable[m.playerIndex].gun].reloadTime
        end
    end

    -- first person
    if firstPerson then
        handle_first_person(m)
    else
        djui_hud_set_mouse_locked(false)
        bhGain = 1
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
    if m.playerIndex == 0 and firstPerson then return false end
    return gPlayerSyncTable[m.playerIndex].modelId == E_MODEL_GORDON
end

--- @param m MarioState
--- @param o Object
function on_interact(m, o, type, value)
    if type == INTERACT_COIN and get_ammo(m) + o.oDamageOrCoinValue <= gunTable[localGun].maxAmmo then
        set_ammo(m, get_ammo(m) + o.oDamageOrCoinValue)
    end
end
--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].gun = GUN_PISTOL

    gPlayerSyncTable[m.playerIndex].ammoPistol = gunTable[GUN_PISTOL].maxAmmo
    gPlayerSyncTable[m.playerIndex].ammoMagnum = gunTable[GUN_MAGNUM].maxAmmo
    
    reloadTimer = gunTable[GUN_PISTOL].reloadTime
    shootTimer = gunTable[GUN_PISTOL].shootTime

    gPlayerSyncTable[m.playerIndex].shotsFired = 0

    -- first person
    gPlayerSyncTable[m.playerIndex].metalCap = false
end

function on_warp()
    gMarioStates[0].health = 0x880
    despawn_gun()
    if gGlobalSyncTable.warpAmmo then
        set_ammo(gMarioStates[0], gunTable[localGun].maxAmmo)
    end
    corpse = nil

    if firstPerson then
        disable_fp()
        enable_fp()

        gLakituState.yaw = gMarioStates[0].faceAngle.y + 0x8000
    end
    yOffset = 0
    totwcTimer = 0
end

function on_sync_valid()
    syncing = true
    local m = gMarioStates[0]
    if m.health > 0xff and m.action ~= ACT_IN_CANNON and m.action ~= ACT_DISAPPEARED then
        spawn_gun()
        -- audio_sample_play(gunTable[GUN_PISTOL].reloadSound, m.pos, 0.75)
        if arm == nil and firstPerson then
            spawn_arm()
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_INTERACT, on_interact)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_SYNC_VALID, on_sync_valid)

smlua_text_utils_secret_star_replace(COURSE_SA, "   BLACK MESA")

gServerSettings.playerInteractions = 2
gServerSettings.bubbleDeath = 0