-- localize functions to improve performance
local get_id_from_behavior,cur_obj_set_behavior,find_floor_height,le_remove_light,obj_mark_for_deletion,le_set_light_intensity,obj_set_model_extended,le_set_light_color,obj_has_model_extended,obj_copy_pos,le_set_light_pos,le_add_light,sins,coss,get_first_person_enabled,vec3f_dist,vec3f_to_object_pos = get_id_from_behavior,cur_obj_set_behavior,find_floor_height,le_remove_light,obj_mark_for_deletion,le_set_light_intensity,obj_set_model_extended,le_set_light_color,obj_has_model_extended,obj_copy_pos,le_set_light_pos,le_add_light,sins,coss,get_first_person_enabled,vec3f_dist,vec3f_to_object_pos

local sFlameBhvs = {
    [id_bhvFireParticleSpawner]       = true,
    [id_bhvFlame]                     = true,
    [id_bhvFlameBouncing]             = true,
    [id_bhvFlameFloatingLanding]      = true,
    [id_bhvFlameLargeBurningOut]      = true,
    [id_bhvFlameMovingForwardGrowing] = true,
    [id_bhvFlamethrowerFlame]         = true,
    [id_bhvBouncingFireballFlame]     = true,
    [id_bhvLllRotatingHexFlame]       = true,
    [id_bhvFlyguyFlame]               = true,
    [id_bhvVolcanoFlames]             = true,
    [id_bhvFlameBowser]               = true,
}

--- @param o Object
function bhv_nm_object_light_init(o)
    local bhv = get_id_from_behavior(o.parentObj.behavior)

    -- archived for historical purposes:
    -- I have an absolute zero fucking understanding of this shit at all
    -- It should be id_bhvCoinFormationSpawn but its not but it is because
    -- if I don't add lights to it then it doesn't light up at all
    -- cur_obj_set_behavior(bhvYellowCoin);
    -- WHY?????
    -- FUCKING WHYYYYYY??
    -- WHO THE FUCK THOUGHT THIS WAS A GOOD IDEA???
    -- I'M JUST FINDING OUT ABOUT THIS FUNCTION NOW
    -- THIS IS THE WORST BEHAVIOR FUNCTION DUDE
    if bhv == id_bhvYellowCoin and get_id_from_behavior(o.parentObj.parentObj.behavior) == id_bhvCoinFormation then
        if gNetworkPlayers[0].currLevelNum == LEVEL_PSS or
           (gNetworkPlayers[0].currLevelNum == LEVEL_BOB and o.parentObj.oPosY > find_floor_height(o.parentObj.oPosX, o.parentObj.oPosY + 200, o.parentObj.oPosZ) + 2048) then
            le_remove_light(o.oLightID)
            obj_mark_for_deletion(o)
            return
        end
    end

    if bhv == id_bhvExclamationBox or bhv == id_bhvBlueCoinSwitch then
        le_set_light_use_surface_normals(o.oLightID, false)
    end
end

--- @param o Object
function bhv_nm_object_light_loop(o)
    if o.parentObj == nil or o.parentObj.activeFlags == ACTIVE_FLAG_DEACTIVATED then
        le_remove_light(o.oLightID)
        obj_mark_for_deletion(o)
        return
    end

    local bhv = get_id_from_behavior(o.parentObj.behavior)

    -- check if the object is hidden/intangible and there shouldn't be a light
    if (bhv == id_bhvHiddenBlueCoin or bhv == id_bhvExclamationBox) and
       ((o.parentObj.header.gfx.node.flags & GRAPH_RENDER_ACTIVE) == 0 or
        (o.parentObj.header.gfx.node.flags & GRAPH_RENDER_INVISIBLE) ~= 0 or
        o.parentObj.oIntangibleTimer < 0) then
        le_set_light_intensity(o.oLightID, 0)
        return
    end

    if gCoinBhvs[bhv] ~= nil then
        le_set_light_intensity(o.oLightID, if_then_else(coinLights, 5, 0))
    else
        le_set_light_intensity(o.oLightID, if_then_else(bhv == id_bhvFlame or bhv == id_bhvBlueCoinSwitch, 10, 5))
    end

    -- special colors
    if sFlameBhvs[bhv] ~= nil then
        if in_vanilla_level(LEVEL_LLL) or in_vanilla_level(LEVEL_BITFS) then
            obj_set_model_extended(o.parentObj, E_MODEL_BLUE_FLAME)
            le_set_light_color(o.oLightID, 100, 100, 255)
        elseif obj_has_model_extended(o.parentObj, E_MODEL_BLUE_FLAME) ~= 0 then
            le_set_light_color(o.oLightID, 100, 100, 255)
        end
    elseif bhv == id_bhvKlepto then
        if o.parentObj.oAnimState ~= KLEPTO_ANIM_STATE_HOLDING_STAR then
            le_set_light_intensity(o.oLightID, 0)
        end
    end

    obj_copy_pos(o, o.parentObj)
    le_set_light_pos(o.oLightID, o.oPosX, o.oPosY + 30, o.oPosZ)
end


--- @param o Object
function bhv_nm_bowser_light_init(o)
    if o.oBehParams2ndByte == 1 then
        if in_vanilla_level(LEVEL_BOWSER_3) then
            o.oLightID = le_add_light(0, 2000, 0, 200, 50, 255, 10000, 20) -- purple
        elseif in_vanilla_level(LEVEL_BOWSER_2) then
            o.oLightID = le_add_light(0, 2000, 0, 0, 100, 255, 10000, 10) -- blue
        else
            o.oLightID = le_add_light(0, 2000, 0, 0, 127, 255, 5000, 5) -- light blue
        end
        o.oFaceAngleYaw = 0x0000
    elseif o.oBehParams2ndByte == 2 then
        if in_vanilla_level(LEVEL_BOWSER_3) then
            o.oLightID = le_add_light(0, 2000, 0, 127, 255, 0, 10000, 20) -- green
        elseif in_vanilla_level(LEVEL_BOWSER_2) then
            o.oLightID = le_add_light(0, 2000, 0, 0, 255, 127, 10000, 10) -- mint green
        else
            o.oLightID = le_add_light(0, 2000, 0, 127, 255, 0, 5000, 10) -- green
        end
        o.oFaceAngleYaw = 0x8000
    end
end

--- @param o Object
function bhv_nm_bowser_light_loop(o)
    o.oPosX = sins(o.oFaceAngleYaw) * 3000
    o.oPosZ = coss(o.oFaceAngleYaw) * 3000

    le_set_light_pos(o.oLightID, o.oPosX, o.oPosY, o.oPosZ)

    o.oFaceAngleYaw = o.oFaceAngleYaw + if_then_else(in_vanilla_level(LEVEL_BOWSER_3), 0x800, 0x400)
end


--- @param o Object
function bhv_nm_flashlight_loop(o)
    le_set_light_intensity(o.oLightID, 5)

    local fp = get_first_person_enabled()
    local pos = {
        x = gMarioStates[0].pos.x,
        y = gMarioStates[0].pos.y + 120,
        z = gMarioStates[0].pos.z
    }

    local yaw = if_then_else(fp, gFirstPersonCamera.yaw + 0x8000, gMarioStates[0].faceAngle.y)

    local dirX = sins(yaw) * 300
    local dirY = if_then_else(fp, -gFirstPersonCamera.pitch * 0.06, 0)
    local dirZ = coss(yaw) * 300

    local raycast = collision_find_surface_on_ray(pos.x, pos.y, pos.z, dirX, dirY, dirZ)
    if vec3f_dist(pos, raycast.hitPos) < 600 then
        vec3f_to_object_pos(o, vec3f_lerp(pos, raycast.hitPos, 0.5))
    else
        o.oPosX = pos.x + dirX
        o.oPosY = pos.y + dirY
        o.oPosZ = pos.z + dirZ
    end

    le_set_light_pos(o.oLightID, o.oPosX, o.oPosY, o.oPosZ)
end