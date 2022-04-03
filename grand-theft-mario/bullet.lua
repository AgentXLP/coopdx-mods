define_custom_obj_fields({
    oBulletTimer = 'u32'
})

function bhv_bullet_init(obj)
    obj_set_billboard(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.45)

    obj.oIntangibleTimer = 2
    obj.oDamageOrCoinValue = gGlobalSyncTable.dmg
    obj.oInteractType = INTERACT_DAMAGE

    -- hitbox
    obj.hitboxRadius = 80
    obj.hitboxHeight = 80

    -- physics
    obj.oWallHitboxRadius =  30
    obj.oGravity          =  0
    obj.oBounciness       =  0
    obj.oDragStrength     =  0
    obj.oFriction         =  0
    obj.oBuoyancy         =  0

    obj.oBulletTimer = 100 -- time until bullet despawns

    network_init_object(obj, true, nil)
end

function bhv_bullet_loop(obj)
    cur_obj_update_floor_and_walls()
    if (obj.oMoveFlags & OBJ_MOVE_HIT_WALL) ~= 0 then
        spawn_mist_particles()
        obj_mark_for_deletion(obj)
    end

    -- timer that counts down until the bullet is automatically destroyed
    if obj.oBulletTimer >= 1 then
        obj.oBulletTimer = obj.oBulletTimer - 1
    else
        obj_mark_for_deletion(obj)
    end

    if obj.oTimer <= 1 then
        obj.oForwardVel = 220
    else
        obj.oForwardVel = 65
    end

    cur_obj_move_xz_using_fvel_and_yaw()
end

id_bhvBullet = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_bullet_init, bhv_bullet_loop)