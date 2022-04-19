define_custom_obj_fields({
    oBulletTimer = 'u32'
})

function bhv_bullet_init(o)
    obj_set_billboard(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.45)

    o.oIntangibleTimer = 2
    o.oInteractType = INTERACT_DAMAGE

    -- hitbox
    o.hitboxRadius = 80
    o.hitboxHeight = 80

    -- physics
    o.oWallHitboxRadius =  30
    o.oGravity          =  0
    o.oBounciness       =  0
    o.oDragStrength     =  0
    o.oFriction         =  0
    o.oBuoyancy         =  0

    o.oBulletTimer = 100 -- time until bullet despawns

    network_init_object(o, true, nil)
end

function bullet_hit(o)
    spawn_mist_particles()
    obj_mark_for_deletion(o)
end

function spawn_coin(o)
    spawn_sync_object(
        id_bhvMovingYellowCoin,
        E_MODEL_YELLOW_COIN,
        o.oPosX, o.oPosY, o.oPosZ,
        nil
    )
end

local dist = 200
timesBossHit = 0
function bhv_bullet_loop(o)
    cur_obj_update_floor_and_walls()
    if (o.oMoveFlags & OBJ_MOVE_HIT_WALL) ~= 0 then
        bullet_hit(o)
    end

    local soundPos = gMarioStates[0].marioObj.header.gfx.cameraToObject

    -- this is major cringe, don't ever do this
    local toad = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvToadMessage))
    local goomba = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvGoomba))
    local koopa = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvKoopa))
    local bobomb = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvBobomb))
    local bowser = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvBowser))
    local plant = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvPiranhaPlant))
    local box = cur_obj_nearest_object_with_behavior(get_behavior_from_id(id_bhvBreakableBox))
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
            gGlobalSyncTable.bossTolerance = 3
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

    

    if o.oTimer <= 1 then
        o.oForwardVel = 220
    elseif o.oTimer < 125 then
        o.oForwardVel = 65
    else
        obj_mark_for_deletion(o)
    end

    cur_obj_move_xz_using_fvel_and_yaw()
end

id_bhvBullet = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_bullet_init, bhv_bullet_loop)