-- name: Tree Billboard Fix
-- description: Tree Billboard Fix\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nIn sm64ex, trees uses cylboard instead of billboard which makes them only rotate in relation the camera horizontally, this mod fixes that.

--- @param o Object
function bhv_tree_init(o)
    obj_set_billboard(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_POLE
    o.hitboxRadius = 80
    o.hitboxHeight = 500
    o.oIntangibleTimer = 0
end

--- @param o Object
function bhv_tree_loop(o)
    bhv_pole_base_loop()
end

id_bhvTree = hook_behavior(id_bhvTree, OBJ_LIST_POLELIKE, true, bhv_tree_init, bhv_tree_loop)