gGlobalSyncTable.bossTolerance = 5 -- times a boss needs to be shot before taking damage, networking it would be good I think
gGlobalSyncTable.infAmmo = true
gGlobalSyncTable.warpAmmo = true

gun = nil

SOUND_CUSTOM_DRYFIRE = audio_sample_load("dry.mp3")

weaponTable = {}
weaponCount = 0

function get_ammo()
    local g = gPlayerSyncTable[0].weapon
    return gPlayerSyncTable[0]["ammo" .. weaponTable[g].name]
end

function set_ammo(value)
    local g = gPlayerSyncTable[0].weapon
    gPlayerSyncTable[0]["ammo" .. weaponTable[g].name] = value
end

function common_shoot()
    local m = gMarioStates[0]
    local localWeapon = gPlayerSyncTable[0].weapon
    if shootTimer == weaponTable[localWeapon].shootTime then
        if get_ammo() > 0 then
            spawn_sync_object(
                id_bhvBullet,
                weaponTable[localWeapon].bullet,
                m.pos.x, m.pos.y + 60, m.pos.z,
                --- @param o Object
                function (o)
                    o.oDamageOrCoinValue = weaponTable[localWeapon].dmg
                    o.header.gfx.scale.x = weaponTable[localWeapon].bulletScale
                    o.header.gfx.scale.y = weaponTable[localWeapon].bulletScale
                    o.header.gfx.scale.z = weaponTable[localWeapon].bulletScale

                    o.oBulletOwner = gNetworkPlayers[0].globalIndex

                    if sPlayerFirstPerson.enabled or (m.input & INPUT_FIRST_PERSON) ~= 0 then
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
    
            set_ammo(get_ammo() - 1)
            gPlayerSyncTable[0].shotsFired = gPlayerSyncTable[0].shotsFired + 1
            shootTimer = 0
        else
            audio_sample_play(SOUND_CUSTOM_DRYFIRE, m.pos, 0.5)
        end
    end
end

define_custom_obj_fields({
    oGunOwner = 'u32',
    oCompensation = 'u32'
})

--- @param m MarioState
function active_player(m)
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
    return is_player_active(m)
end


--- @param o Object
function bhv_gun_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.12)

    o.hitboxRadius = 0
    o.hitboxHeight = 0

    network_init_object(o, true, { 'oGunOwner' })
end
--- @param o Object
function bhv_gun_loop(o)
    local np = network_player_from_global_index(o.oGunOwner)
    if np == nil then
        obj_mark_for_deletion(o)
        return
    end

    local m = gMarioStates[np.localIndex]
    if not active_player(m) then
        obj_mark_for_deletion(o)
        return
    end

    if m.action ~= ACT_FLYING and (m.action & ACT_FLAG_SWIMMING) == 0 then
        -- it works, it just works.
        if o.oGunOwner ~= gNetworkPlayers[0].globalIndex then
            o.oPosX = get_hand_foot_pos_x(m, 0) + m.vel.x
            if m.action ~= ACT_JUMP then
                o.oPosY = get_hand_foot_pos_y(m, 0)
            else
                o.oPosY = get_hand_foot_pos_y(m, 0) + 25
            end
            o.oPosZ = get_hand_foot_pos_z(m, 0) + m.vel.z
        else
            if sPlayerFirstPerson.enabled then
                o.oPosX = m.pos.x + m.vel.x + 5 * math.sin(m.faceAngle.y)
                o.oPosY = -11000
                o.oPosZ = m.pos.z + m.vel.z + 5 * math.cos(m.faceAngle.y)
            else
                o.oPosX = get_hand_foot_pos_x(m, 0) + m.vel.x
                if m.action ~= ACT_JUMP then
                    o.oPosY = get_hand_foot_pos_y(m, 0)
                else
                    o.oPosY = get_hand_foot_pos_y(m, 0) + 25
                end
                o.oPosZ = get_hand_foot_pos_z(m, 0) + m.vel.z
            end
        end
    else
        o.oPosX = m.pos.x
        o.oPosZ = m.pos.z
        if o.oGunOwner == gNetworkPlayers[0].globalIndex and sPlayerFirstPerson.enabled then
            o.oPosY = -11000
        else
            o.oPosY = m.pos.y + 50
        end
    end

    if o.oPosY == o.header.gfx.prevPos.y and o.oGunOwner ~= gNetworkPlayers[0].globalIndex then
        if o.oCompensation < 30 then o.oCompensation = o.oCompensation + 1 end
    else o.oCompensation = 0 end

    if o.oCompensation >= 30 then
        o.oPosX = m.pos.x + m.vel.x
        if m.action ~= ACT_JUMP then
            o.oPosY = m.pos.y
        else
            o.oPosY = m.pos.y + 25
        end
        o.oPosZ = m.pos.z + m.vel.z
    end

    o.oFaceAnglePitch = 0
    o.oFaceAngleYaw = m.faceAngle.y
    o.oFaceAngleRoll = 0
end
id_bhvGun = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_gun_init, bhv_gun_loop)

local vgun = nil
--- @param m MarioState
function weapon_change(m, new)
    if gun == nil then
        return
    end
    -- if gPlayerSyncTable[0].weapon == new and sPlayerFirstPerson.enabled then
    --     deployHeight = deployMax
    -- elseif sPlayerFirstPerson.enabled then
    --     deployHeight = deployMin
    -- end
    gPlayerSyncTable[m.playerIndex].weapon = new
    local localWeapon = gPlayerSyncTable[m.playerIndex].weapon
    reloadTimer = weaponTable[localWeapon].reloadTime
    shootTimer = weaponTable[localWeapon].shootTime

    obj_mark_for_deletion(gun)
    spawn_weapon()
end

function despawn_weapon()
    if gun ~= nil then
        obj_mark_for_deletion(gun)
        -- gun = nil
    end
end

function spawn_weapon()
    local m = gMarioStates[0]
    gun = spawn_sync_object(
        id_bhvGun,
        weaponTable[gPlayerSyncTable[0].weapon].model,
        get_hand_foot_pos_x(m, 0), get_hand_foot_pos_y(m, 0), get_hand_foot_pos_z(m, 0),
        function (o)
            o.oGunOwner = gNetworkPlayers[0].globalIndex
        end
    )
    if weaponTable[gPlayerSyncTable[0].weapon].init ~= nil then weaponTable[gPlayerSyncTable[0].weapon].init() end
end



-- non gun weapon template
-- WEAPON_CROWBAR = 2
--
-- function loop()
--     local m = gMarioStates[0]
--     if (m.controller.buttonPressed & B_BUTTON) ~= 0 and (m.action == ACT_PUNCHING or m.action == ACT_MOVE_PUNCHING or m.action == ACT_WATER_PUNCH) then
--         audio_sample_play(weaponTable[WEAPON_CROWBAR].shootSound, m.pos, 1)
--     end
-- end
--
-- weaponTable[WEAPON_CROWBAR] = {
--     name = "Crowbar",
--     gun = false,
--     call = nil,
--     init = nil,
--     loop = loop,
--     model = E_MODEL_CANNON_BARREL,
--     arm = "arm",
--     vmodel = "crowbar",
--     shootSound = audio_sample_load("swish.mp3")
-- }
-- weaponCount = weaponCount + 1