E_MODEL_FLOOD = smlua_model_util_get_id("flood_geo")
E_MODEL_CTT = smlua_model_util_get_id("ctt_geo") -- easter egg in the distance

--- @param o Object
function bhv_water_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oAnimState = levels[map()].type

    o.header.gfx.skipInViewCheck = true

    o.oFaceAnglePitch = 0
    o.oFaceAngleRoll = 0
end

--- @param o Object
function bhv_water_loop(o)
    if o.oPosY < levels[gNetworkPlayers[0].currLevelNum].stop then o.oPosY = gGlobalSyncTable.waterLevel end
    if o.oPosY > levels[gNetworkPlayers[0].currLevelNum].stop then o.oPosY = levels[gNetworkPlayers[0].currLevelNum].stop end

    if map() ~= LEVEL_SSL then
        o.oFaceAngleYaw = o.oTimer * 14
    end
end

id_bhvWater = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_water_init, bhv_water_loop)

function is_water()
    return obj_get_first_with_behavior_id(id_bhvWater) ~= nil
end

--- @param o Object
function bhv_custom_static_object_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    if o.header.gfx.skipInViewCheck ~= nil then o.header.gfx.skipInViewCheck = true end
    set_override_far(50000)
end

id_bhvCustomStaticObject = hook_behavior(nil, OBJ_LIST_LEVEL, true, bhv_custom_static_object_init, nil)

--- @param o Object
function bhv_final_star_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.hitboxRadius = 1000
    o.hitboxHeight = 1000
end

--- @param o Object
function bhv_final_star_loop(o)
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x800
end

id_bhvFinalStar = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_final_star_init, bhv_final_star_loop)

--- @param obj Object
function obj_mark_for_deletion_on_sync(obj)
    if gNetworkPlayers[0].currAreaSyncValid then obj_mark_for_deletion(obj) end
end

hook_behavior(id_bhvHoot, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvStar, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvCannon, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvRedCoin, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvWarpPipe, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvFadingWarp, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvEyerokBoss, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvBalconyBigBoo, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvRecoveryHeart, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvExclamationBox, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvUkiki, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)
hook_behavior(id_bhvChuckya, OBJ_LIST_UNIMPORTANT, true, nil, obj_mark_for_deletion_on_sync)