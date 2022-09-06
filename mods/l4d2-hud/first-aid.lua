HEALING_TIME = 150

healedSounds = {
    CHAR_SOUND_HAHA,
    CHAR_SOUND_LETS_A_GO,
    CHAR_SOUND_OKEY_DOKEY
}

--- @param m MarioState
function act_healing(m)
    if (m.controller.buttonDown & U_JPAD) == 0 then set_mario_action(m, ACT_IDLE, 0) end

    local anims = {
        MARIO_ANIM_START_REACH_POCKET,
        MARIO_ANIM_REACH_POCKET,
        MARIO_ANIM_STOP_REACH_POCKET,
        MARIO_ANIM_MISSING_CAP
    }

    if is_anim_at_end(m) ~= 0 and anims[m.actionState + 2] ~= nil then m.actionState = m.actionState + 1 end
    set_mario_animation(m, anims[m.actionState + 1])

    if m.actionTimer < HEALING_TIME then
        m.actionTimer = m.actionTimer + 1
    else
        gPlayerSyncTable[m.playerIndex].firstAid = false
        m.health = m.health + 0x680
        play_character_sound(m, healedSounds[math.random(1, 3)])
        m.invincTimer = 30
        set_mario_action(m, ACT_IDLE, 0)
    end

    m.marioObj.header.gfx.pos.y = m.pos.y
end
ACT_HEALING = allocate_mario_action(ACT_FLAG_IDLE | ACT_FLAG_PAUSE_EXIT | ACT_FLAG_STATIONARY)

--- @param m MarioState
function mario_update(m)
    if m.playerIndex ~= 0 then return end

    if not gGlobalSyncTable.sm64Health and (m.action & ACT_FLAG_IDLE) ~= 0 and (m.controller.buttonPressed & U_JPAD) ~= 0 and gPlayerSyncTable[0].firstAid and m.health <= 0x680 then
        set_mario_action(m, ACT_HEALING, 0)
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].firstAid = false
end

--- @param o Object
function on_object_unload(o)
    -- thanks PeachyPeach
    local m = gMarioStates[0]
    if (o.header.gfx.node.flags & GRAPH_RENDER_INVISIBLE) == 0 and (
        obj_has_behavior_id(o, id_bhv1Up) ~= 0 or
        obj_has_behavior_id(o, id_bhv1upJumpOnApproach) ~= 0 or
        obj_has_behavior_id(o, id_bhv1upRunningAway) ~= 0 or
        obj_has_behavior_id(o, id_bhv1upSliding) ~= 0 or
        obj_has_behavior_id(o, id_bhv1upWalking) ~= 0 or
        obj_has_behavior_id(o, id_bhvHidden1up) ~= 0 or
        obj_has_behavior_id(o, id_bhvHidden1upInPole) ~= 0) and
        obj_check_hitbox_overlap(o, m.marioObj) ~= 0 then
        gMarioStates[0].numLives = gMarioStates[0].numLives - 1
        if not gPlayerSyncTable[0].firstAid then
            gPlayerSyncTable[0].firstAid = true
        end
    end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)
hook_event(HOOK_ON_OBJECT_UNLOAD, on_object_unload)

hook_mario_action(ACT_HEALING, act_healing, INTERACT_PLAYER)