GUN_SHOOT_SPEED = 180

define_custom_obj_fields({
    oBulletTimer = 'u32',
    oBulletOwner = 'u32'
})

--- @param o Object
function bhv_bullet_init(o)
    obj_set_billboard(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    o.oIntangibleTimer = 2
    o.oInteractType = INTERACT_DAMAGE

    o.hitboxRadius = 60
    o.hitboxHeight = 60

    o.oForwardVel = GUN_SHOOT_SPEED

    -- physics
    o.oWallHitboxRadius =  30
    o.oGravity          =  0
    o.oBounciness       =  0
    o.oDragStrength     =  0
    o.oFriction         =  0
    o.oBuoyancy         =  0

    o.oBulletTimer = 100 -- time until bullet despawns

    local i = network_local_index_from_global(o.oBulletOwner)
    audio_sample_play(weaponTable[gPlayerSyncTable[i].weapon].shootSound, gMarioStates[i].pos, 0.5)

    network_init_object(o, true, { "oBulletOwner" })
end

--- @param o Object
function bullet_hit(o)
    spawn_mist_particles()
    obj_mark_for_deletion(o)
end

--- @param o Object
function spawn_coin(o)
    spawn_sync_object(
        id_bhvMovingYellowCoin,
        E_MODEL_YELLOW_COIN,
        o.oPosX, o.oPosY, o.oPosZ,
        nil
    )
end

local dist = 200
--- @param o Object
function bhv_bullet_loop(o)
    cur_obj_update_floor_and_walls()
    if (o.oMoveFlags & OBJ_MOVE_HIT_WALL) ~= 0 then
        bullet_hit(o)
    end

    local soundPos = gMarioStates[0].marioObj.header.gfx.cameraToObject

    -- thank you prince frizzy
    local toad = obj_get_nearest_object_with_behavior_id(o, id_bhvToadMessage)
    local goomba = obj_get_nearest_object_with_behavior_id(o, id_bhvGoomba)
    local koopa = obj_get_nearest_object_with_behavior_id(o, id_bhvKoopa)
    local bobomb = obj_get_nearest_object_with_behavior_id(o, id_bhvBobomb)
    local bowser = obj_get_nearest_object_with_behavior_id(o, id_bhvBowser)
    local plant = obj_get_nearest_object_with_behavior_id(o, id_bhvPiranhaPlant)
    local box = obj_get_nearest_object_with_behavior_id(o, id_bhvBreakableBox)
    if toad ~= nil and dist_between_objects(o, toad) < dist then
        obj_mark_for_deletion(toad)
        spawn_coin(o)
        bullet_hit(o)
    elseif goomba ~= nil and dist_between_objects(o, goomba) < dist then
        -- can't let my homies lose out on 5 coins
        if (goomba.oGoombaSize & 1) ~= 0 then
            goomba.oInteractStatus = ATTACK_GROUND_POUND_OR_TWIRL | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        else
            goomba.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        end
        bullet_hit(o)
    elseif koopa ~= nil and dist_between_objects(o, koopa) < dist then
        koopa.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        bullet_hit(o)
    elseif bobomb ~= nil and dist_between_objects(o, bobomb) < dist then
        bobomb.oAction = 1
        play_sound(SOUND_GENERAL2_BOBOMB_EXPLOSION, soundPos)
        bullet_hit(o)
    elseif bowser ~= nil and dist_between_objects(o, bowser) < dist then
        if gGlobalSyncTable.bossTolerance > 0 then
            gGlobalSyncTable.bossTolerance = gGlobalSyncTable.bossTolerance - 1
        else
            gGlobalSyncTable.bossTolerance = 5
            bowser.oAction = 4
            bowser.oHealth = bowser.oHealth - 1
        end
        bullet_hit(o)
    elseif plant ~= nil and dist_between_objects(o, plant) < dist then
        plant.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED
        bullet_hit(o)
    elseif box ~= nil and dist_between_objects(o, box) < dist then
        box.oInteractStatus = ATTACK_KICK_OR_TRIP | INT_STATUS_INTERACTED | INT_STATUS_WAS_ATTACKED | INT_STATUS_STOP_RIDING
        bullet_hit(o)
    end

    -- local i = network_local_index_from_global(o.oBulletOwner)
    -- local m = gMarioStates[i]
    -- if i == 0 and obj_has_model_extended(o, weaponTable[gPlayerSyncTable[i].weapon].bullet) and ((m.action & ACT_FLAG_AIR) == 0 or m.action == ACT_STATIC_JUMP) and o.oPosY < o.oFloorHeight + 60 then
    --     set_mario_action(m, ACT_FREEFALL, 0)
    --     m.faceAngle.y = m.intendedYaw
    --     m.vel.y = m.vel.y + 60
    --     m.forwardVel = m.forwardVel * 2
    -- end

    if o.oTimer > 150 then
        obj_mark_for_deletion(o)
    end

    if o.oVelY == 0 then cur_obj_move_xz_using_fvel_and_yaw()
    else cur_obj_move_using_vel() end
end

id_bhvBullet = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_bullet_init, bhv_bullet_loop)

--- @param m MarioState
--- @param o Object
function allow_interact(m, o)
    local b = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvBullet)
    if o == b then
        if o.oBulletOwner == gNetworkPlayers[m.playerIndex].globalIndex then return false end
    else
        if b ~= nil then obj_mark_for_deletion(b) end
        return true
    end
end

hook_event(HOOK_ALLOW_INTERACT, allow_interact)