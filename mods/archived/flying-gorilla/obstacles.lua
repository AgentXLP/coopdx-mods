E_MODEL_CUBE = smlua_model_util_get_id("cube_geo")
COL_CUBE = smlua_collision_util_get("cube_collision")

E_MODEL_WATER = smlua_model_util_get_id("water_geo")
COL_WATER = smlua_collision_util_get("water_collision")

E_MODEL_CREATURE = smlua_model_util_get_id("creature_geo")
COL_CREATURE = smlua_collision_util_get("creature_collision")

--- @param o Object
function bhv_solid_object_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oCollisionDistance = 1000
end

--- @param o Object
function bhv_solid_object_loop(o)
    if gMarioStates[0].actionTimer ~= 0 then return end

    o.oPosZ = o.oPosZ - OFFSET_SPEED

    load_object_collision_model()
end

id_bhvSolidObject = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_solid_object_init, bhv_solid_object_loop)

--- @param o Object
function bhv_water_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oCollisionDistance = 1000
    o.collisionData = COL_WATER
    o.oHomeY = o.oPosY
    o.oIntangibleTimer = 30
end

--- @param o Object
function bhv_water_loop(o)
    if gMarioStates[0].actionTimer ~= 0 or o.oIntangibleTimer ~= 0 then return end

    o.oPosY = o.oHomeY + math.sin(o.oTimer * 0.1) * 500
    o.oPosZ = o.oPosZ - OFFSET_SPEED

    load_object_collision_model()
end

id_bhvWater = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_water_init, bhv_water_loop)

--- @param o Object
function bhv_enemy_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oCollisionDistance = 1000
    o.collisionData = COL_CREATURE
end

--- @param o Object
function bhv_enemy_loop(o)
    if gMarioStates[0].actionTimer ~= 0 then return end

    o.oPosX = math.sin(o.oTimer * 0.1) * 300
    o.oPosZ = o.oPosZ - OFFSET_SPEED

    load_object_collision_model()
end

id_bhvEnemy = hook_behavior(nil, OBJ_LIST_SURFACE, true, bhv_enemy_init, bhv_enemy_loop)

function spawn_obstacles()
    for i = 1, 4 do
        spawn_non_sync_object(
            id_bhvSolidObject,
            E_MODEL_CUBE,
            300 * math.random(-1, 1), 0, (6000 * pieceCounter) - (gameTimer * OFFSET_SPEED) + (1000 * i),
            --- @param o Object
            function(o)
                o.collisionData = COL_CUBE
                o.oFaceAngleYaw = 0
                o.oFaceAnglePitch = 0
                o.oFaceAngleRoll = 0
            end
        )

        if math.random(0, 1) == 0 then
            spawn_non_sync_object(
                id_bhvWater,
                E_MODEL_WATER,
                0, -500, (6000 * pieceCounter) - (gameTimer * OFFSET_SPEED) + 7500,
                --- @param o Object
                function(o)
                    o.oFaceAngleYaw = 0
                    o.oFaceAnglePitch = 0
                    o.oFaceAngleRoll = 0
                end
            )
        end
    end

    if math.random(0, 5) == 0 then
        spawn_non_sync_object(
            id_bhvEnemy,
            E_MODEL_CREATURE,
            0, 200, (6000 * pieceCounter) - (gameTimer * OFFSET_SPEED) + 500,
            --- @param o Object
            function(o)
                o.oFaceAngleYaw = 0
                o.oFaceAnglePitch = 0
                o.oFaceAngleRoll = 0
            end
        )
    end
end