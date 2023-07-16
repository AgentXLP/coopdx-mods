define_custom_obj_fields({
    oOwner = 's32',
    oNpcTalkingTo = 's32',
    oNpcId = 'u32',
    oDialogId = 'u32'
})

NPC_INTERACT_RANGE = 400

lastNpcId = 0

-- localize functions to improve performance
local max,obj_mark_for_deletion,find_floor_height,spawn_non_sync_object,smlua_anim_util_set_animation,dist_between_objects,network_local_index_from_global,set_mario_action,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id = max,obj_mark_for_deletion,find_floor_height,spawn_non_sync_object,smlua_anim_util_set_animation,dist_between_objects,network_local_index_from_global,set_mario_action,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id

local function increment_npc_id()
    lastNpcId = lastNpcId + 1
    return lastNpcId
end

--- @param o Object
local function bhv_npc_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.globalPlayerIndex = 0
    o.oNpcTalkingTo = -1
    o.oNpcId = increment_npc_id()
    local targetDialogId = max(o.oBehParams >> 24, 1)
    if targetDialogId == 1 then
        if gGlobalSyncTable.stars >= STARS then
            obj_mark_for_deletion(o)
            return
        elseif gGlobalSyncTable.stars > 0 then
            o.oBehParams = 0x02000000
        end
    end

    o.oPosY = find_floor_height(o.oPosX, o.oPosY + 200, o.oPosZ)
    o.oMoveAngleYaw = o.oFaceAngleYaw

    spawn_non_sync_object(
        id_bhvLetter,
        E_MODEL_LETTER,
        o.oPosX, o.oPosY + 250, o.oPosZ,
        --- @param obj Object
        function(obj)
            obj.parentObj = o
            obj.oAnimState = 1
        end
    )

    network_init_object(o, false, { "oNpcId", "oDialogId" })
end

--- @param o Object
local function bhv_npc_loop(o)
    if betrayalCutscene >= 2 then
        obj_mark_for_deletion(o)
        return
    end

    if o.oAction == 0 then
        smlua_anim_util_set_animation(o, "apparition_idle")
        o.oGraphYOffset = 65
    elseif o.oAction == 1 then
        smlua_anim_util_set_animation(o, "apparition_raise_arm")
        o.oGraphYOffset = 75
    end

    if o.oNpcTalkingTo < 0 then
        if dist_between_objects(o, gMarioStates[0].marioObj) < NPC_INTERACT_RANGE and (gMarioStates[0].input & INPUT_B_PRESSED) ~= 0 and (gMarioStates[0].action == ACT_PUNCHING or gMarioStates[0].action == ACT_MOVE_PUNCHING) then
            o.oNpcTalkingTo = gNetworkPlayers[0].globalIndex
            o.oDialogId = max(o.oBehParams >> 24, 1)
        end
    else
        local m = gMarioStates[network_local_index_from_global(o.oNpcTalkingTo)]
        o.oFaceAngleYaw = approach_number(o.oFaceAngleYaw, atan2s(m.pos.z - o.oPosZ, m.pos.x - o.oPosX), 0x200, 0x200)

        if gDialogState.currentDialog == nil then
            set_mario_action(m, ACT_CUTSCENE, 0)
            start_dialog(o.oDialogId, o, true, true, 1000)
            -- hardcoded
            if o.oDialogId == 1 then
                o.oBehParams = 0x02000000
                obj_mark_for_deletion(obj_get_first_with_behavior_id(id_bhvDialogTrigger))
            end
        end
    end
end

id_bhvNpc = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_npc_init, bhv_npc_loop)


--- @return Object|nil
function get_npc_with_id(id)
    local npc = obj_get_first_with_behavior_id(id_bhvNpc)
    local match = nil
    while npc ~= nil do
        if npc.oNpcId == id then
            match = npc
            break
        end
        npc = obj_get_next_with_same_behavior_id(npc)
    end
    return match
end