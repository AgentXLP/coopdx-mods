triggered = false

function bhv_stationary_yoshi_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_IGLOO_BARRIER
    o.oAnimations = gObjectAnimations.yoshi_seg5_anims_05024100

    o.oPosY = find_floor_height(o.oPosX, o.oPosY + 200.0, o.oPosZ)

    o.oIntangibleTimer = 0
    o.hitboxRadius = 160
    o.hitboxHeight = 150
end

function bhv_stationary_yoshi_loop(o)
    cur_obj_init_animation(0)
    if dist_between_objects(o, gMarioStates[0].marioObj) < 500 and triggered == false then
        triggered = true
        play_puzzle_jingle()
        doubleJumps = 5
    end
end

id_bhvStationaryYoshi = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_stationary_yoshi_init, bhv_stationary_yoshi_loop)