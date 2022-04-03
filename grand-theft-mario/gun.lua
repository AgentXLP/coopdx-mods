define_custom_obj_fields({
    oGunTimer = 'u32'
})

function bhv_gun_init(obj)
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    cur_obj_scale(0.12)

    obj.hitboxRadius = 0
    obj.hitboxHeight = 0

    obj.oGunTimer = 300 -- 10 second wait until automatic gun deletion occurs

    network_init_object(obj, true, nil)
end

function bhv_gun_loop(obj)
    -- if pos hasn't changed, probably not the most performant method
    for i=0,(MAX_PLAYERS-1) do
        if obj.oPosX == obj.header.gfx.prevPos.x and obj.oPosY == obj.header.gfx.prevPos.y and (gMarioStates[i].action & ACT_FLAG_SWIMMING) == 0 and obj.oPosZ == obj.header.gfx.prevPos.z then
            obj.oGunTimer = obj.oGunTimer - 1
        else
            obj.oGunTimer = 60
        end 
    end

    if obj.oGunTimer == 0 then
        obj_mark_for_deletion(obj)
    end
end

id_bhvGun = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_gun_init, bhv_gun_loop)