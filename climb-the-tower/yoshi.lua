define_custom_obj_fields({
    oEasterEggTriggered = 'u32'
})

function bhv_stationary_yoshi_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_IGLOO_BARRIER
    o.oAnimations = gObjectAnimations.yoshi_seg5_anims_05024100

    o.oPosY = find_floor_height(o.oPosX, o.oPosY + 200.0, o.oPosZ)

    o.oIntangibleTimer = 0
    o.hitboxRadius = 160
    o.hitboxHeight = 150

    o.oEasterEggTriggered = false
    network_init_object(o, false, { "oEasterEggTriggered" })
end

function bhv_stationary_yoshi_loop(o)
    cur_obj_init_animation(0)
    -- if dist_between_objects(o, gMarioStates[0].marioObj) < 600 and o.oEasterEggTriggered == false then
    --     o.oEasterEggTriggered = true
    --     play_puzzle_jingle()
    --     gMarioStates[0].numLives = gMarioStates[0].numLives + 10
    -- end
end

id_bhvStationaryYoshi = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_stationary_yoshi_init, bhv_stationary_yoshi_loop)