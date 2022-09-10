sticker = nil

define_custom_obj_fields({
    oOwner = 'u32'
})

--- @param o Object
function bhv_sticker_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE

    network_init_object(o, true, { 'oOwner' })
end

--- @param o Object
function bhv_sticker_loop(o)
    local np = network_player_from_global_index(o.oOwner)
    local m = gMarioStates[np.localIndex]
    if np == nil then
        obj_mark_for_deletion(o)
        return
    end

    o.oPosX = m.pos.x
    o.oPosY = m.pos.y
    o.oPosZ = m.pos.z
    o.oFaceAnglePitch = m.marioObj.header.gfx.angle.x
    o.oFaceAngleYaw = m.faceAngle.y
    o.oFaceAngleRoll = 0 -- m.marioObj.header.gfx.angle.z
end

id_bhvSticker = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_sticker_init, bhv_sticker_loop)

--- @param m MarioState
function spawn_sticker(m, model, offset, scale)
    local stick = spawn_sync_object(
        id_bhvSticker,
        model,
        m.pos.x, m.pos.y, m.pos.z,
        --- @param o Object
        function(o)
            o.oOwner = gNetworkPlayers[m.playerIndex].globalIndex
            o.oGraphYOffset = offset
            obj_scale(o, scale)
        end
    )
    if m.playerIndex == 0 then sticker = stick end
end

function despawn_sticker()
    if sticker == nil then return end
    obj_mark_for_deletion(sticker)
    sticker = nil
end