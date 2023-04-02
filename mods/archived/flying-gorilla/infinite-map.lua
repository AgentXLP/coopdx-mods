E_MODEL_FLYING_GORILLA = smlua_model_util_get_id("flying_gorilla_geo")
COL_FLYING_GORILLA = smlua_collision_util_get("flying_gorilla_collision")

--- @param o Object
function bhv_map_piece_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.collisionData = COL_FLYING_GORILLA
    o.oCollisionDistance = 9999
    o.header.gfx.skipInViewCheck = true
end

--- @param o Object
function bhv_map_piece_loop(o)
    if gMarioStates[0].actionTimer ~= 0 then return end

    o.oPosZ = o.oPosZ - OFFSET_SPEED

    load_object_collision_model()
end

id_bhvMapPiece = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_map_piece_init, bhv_map_piece_loop)

function spawn_map_piece()
    spawn_non_sync_object(
        id_bhvMapPiece,
        E_MODEL_FLYING_GORILLA,
        0, 0, (6000 * pieceCounter) - (gameTimer * OFFSET_SPEED),
        --- @param o Object
        function(o)
            o.oFaceAngleYaw = 0
            o.oFaceAnglePitch = 0
            o.oFaceAngleRoll = 0
        end
    )
    pieceCounter = pieceCounter + 1
    if pieceCounter > 0 then
        spawn_obstacles()
    end
end