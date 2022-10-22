-- name: Door Bust
-- description: Door Bust\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds busting down doors by slide kicking into them, flying doors can deal damage to other players and normal doors will respawn after 10 seconds.

define_custom_obj_fields({
    oDoorDespawnedTimer = 'u32',
    oDoorBuster = 'u32'
})

function approach_number(current, target, inc, dec)
    if current < target then
        current = current + inc
        if current > target then
            current = target
        end
    else
        current = current - dec
        if current < target then
            current = target
        end
    end
    return current
end


--- @param o Object
function bhv_broken_door_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = INTERACT_DAMAGE
    o.oIntangibleTimer = 0
    o.oGraphYOffset = -5
    o.oDamageOrCoinValue = 3
    obj_scale(o, 0.85)

    o.hitboxRadius = 80
    o.hitboxHeight = 100
    o.oGravity = 3
    o.oFriction = 0.8
    o.oBuoyancy = 1

    o.oVelY = 50
end

--- @param o Object
function bhv_broken_door_loop(o)
    if o.oForwardVel > 10 then
        object_step()
        if o.oForwardVel < 30 then
            o.oInteractType = 0
        end
    else
        cur_obj_update_floor()
        o.oFaceAnglePitch = approach_number(o.oFaceAnglePitch, -0x4000, 0x500, 0x500)
    end

    -- TODO debug doors getting stuck on toad or whatever

    obj_flicker_and_disappear(o, 300)
end

id_bhvBrokenDoor = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_broken_door_init, bhv_broken_door_loop)

--- @param m MarioState
function mario_update(m)
    if gNetworkPlayers[0].currLevelNum == LEVEL_BBH or gNetworkPlayers[0].currLevelNum == LEVEL_HMC then return end -- problematic

    local door = nil
    if m.playerIndex == 0 then
        door = obj_get_first(OBJ_LIST_SURFACE)
        while door ~= nil do
            if door.behavior == get_behavior_from_id(id_bhvDoor) or door.behavior == get_behavior_from_id(id_bhvStarDoor) then
                if door.oDoorDespawnedTimer > 0 then
                    door.oDoorDespawnedTimer = door.oDoorDespawnedTimer - 1
                else
                    door.oPosY = door.oHomeY
                end
            end

            door = obj_get_next(door)
        end
    end

    door = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvDoor)
    local targetDoor = door
    local starDoor = obj_get_nearest_object_with_behavior_id(m.marioObj, id_bhvStarDoor)
    if starDoor ~= nil then
        if dist_between_objects(m.marioObj, starDoor) < dist_between_objects(m.marioObj, door) then
            targetDoor = starDoor
        else
            targetDoor = door
        end
    end

    if targetDoor ~= nil then
        -- if (m.action == ACT_SLIDE_KICK or m.action == ACT_JUMP_KICK) and dist_between_objects(m.marioObj, targetDoor) < 160 then
        if m.action == ACT_SLIDE_KICK and dist_between_objects(m.marioObj, targetDoor) < 200 then
            local model = E_MODEL_CASTLE_CASTLE_DOOR
            local starRequirement = 0
            -- just make obj_get_model_extended dammit
            if obj_has_model_extended(targetDoor, E_MODEL_CASTLE_DOOR_1_STAR) ~= 0 then
                model = E_MODEL_CASTLE_DOOR_1_STAR
                starRequirement = 1
            elseif obj_has_model_extended(targetDoor, E_MODEL_CASTLE_DOOR_3_STARS) ~= 0 then
                model = E_MODEL_CASTLE_DOOR_3_STARS
                starRequirement = 3
            elseif obj_has_model_extended(targetDoor, E_MODEL_CCM_CABIN_DOOR) ~= 0 then
                model = E_MODEL_CCM_CABIN_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_HMC_METAL_DOOR) ~= 0 then
                model = E_MODEL_HMC_METAL_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_HMC_WOODEN_DOOR) ~= 0 then
                model = E_MODEL_HMC_WOODEN_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_BBH_HAUNTED_DOOR) ~= 0 then
                model = E_MODEL_BBH_HAUNTED_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_CASTLE_METAL_DOOR) ~= 0 then
                model = E_MODEL_CASTLE_METAL_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_CASTLE_CASTLE_DOOR) ~= 0 then
                model = E_MODEL_CASTLE_CASTLE_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_HMC_HAZY_MAZE_DOOR) ~= 0 then
                model = E_MODEL_HMC_HAZY_MAZE_DOOR
            elseif obj_has_model_extended(targetDoor, E_MODEL_CASTLE_GROUNDS_METAL_DOOR) ~= 0 then
                model = E_MODEL_CASTLE_GROUNDS_METAL_DOOR
            elseif targetDoor.behavior == get_behavior_from_id(id_bhvStarDoor) ~= 0 then
                -- model = E_MODEL_CASTLE_STAR_DOOR_8_STARS
                model = E_MODEL_CASTLE_CASTLE_DOOR
                starRequirement = targetDoor.oBehParams2ndByte
            end

            if m.numStars >= starRequirement then
                play_sound(SOUND_GENERAL_BREAK_BOX, m.marioObj.header.gfx.cameraToObject)
                targetDoor.oDoorDespawnedTimer = 339
                targetDoor.oPosY = 9999
                spawn_triangle_break_particles(30, 138, 1, 4)
                spawn_non_sync_object(
                    id_bhvBrokenDoor,
                    model,
                    targetDoor.oPosX, targetDoor.oHomeY, targetDoor.oPosZ,
                    --- @param o Object
                    function(o)
                        --if m.action == ACT_SLIDE_KICK or m.action == ACT_SLIDE_KICK_SLIDE then
                        --    o.oForwardVel = 100
                        --else
                        --    o.oForwardVel = 20

                        --    mario_set_forward_vel(m, -16)
                        --    set_mario_particle_flags(m, PARTICLE_TRIANGLE, 0)
                        --    play_sound(SOUND_ACTION_HIT_2, m.marioObj.header.gfx.cameraToObject)
                        --end
                        o.oDoorBuster = gNetworkPlayers[m.playerIndex].globalIndex
                        o.oForwardVel = 80
                        set_mario_particle_flags(m, PARTICLE_TRIANGLE, 0)
                        play_sound(SOUND_ACTION_HIT_2, m.marioObj.header.gfx.cameraToObject)
                    end
                )
            end
        end
    end
end

--- @param m MarioState
--- @param o Object
function allow_interact(m, o)
    if o.behavior == get_behavior_from_id(id_bhvBrokenDoor) and gNetworkPlayers[m.playerIndex].globalIndex == o.oDoorBuster then return false end
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)

gLevelValues.entryLevel = LEVEL_BBH