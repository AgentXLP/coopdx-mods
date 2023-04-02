--- @param o Object
local function bhv_apparition_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oGraphYOffset = 65
    o.globalPlayerIndex = 1
end

--- @param o Object
local function bhv_apparition_loop(o)
    local s = gMarioStates[15] -- sacrifice
    set_mario_animation(s, MARIO_ANIM_FIRST_PERSON)
    o.header.gfx.animInfo.curAnim = s.marioObj.header.gfx.animInfo.curAnim
end

local id_bhvApparition = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_apparition_init, bhv_apparition_loop)

local function update()
    if not gNetworkPlayers[0].currAreaSyncValid then return end

    if obj_get_first_with_behavior_id(id_bhvApparition) == nil then
        spawn_non_sync_object(
            id_bhvApparition,
            E_MODEL_WALUIGI,
            -515, 4821, -3325,
            --- @param o Object
            function(o)
                o.oFaceAngleYaw = 0
                o.oFaceAnglePitch = 0
                o.oFaceAngleRoll = 0
            end
        )
    end
end

hook_event(HOOK_UPDATE, update)