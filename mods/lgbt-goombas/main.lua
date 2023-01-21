-- name: LGBT Goombas
-- incompatible: moveset
-- description: LGBT Goombas\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds LGBT flag Goombas, toggle with /lgbt [on|off]\n\nPan Goomba: Faster in snow levels, roll\nreplaces slide kick.\n\nBi Goomba: Improved moveset Goomba, has a spin jump and good air control.\n\nTrans Goomba: Loosely based off of Celeste's moveset with double jumps, dashing and wall climbing.\n\nAce Goomba: Crouch and hold down X or\nY to charge up a power jump.\n\nLesbian Goomba: Swims faster and has a special spin attack.\n\n\nSpecial thanks to 0x2480 for creating the strawberry model that goes over stars.

goombas = {
    [CT_MARIO] = smlua_model_util_get_id("goomba_pan_geo"),
    [CT_LUIGI] = smlua_model_util_get_id("goomba_bi_geo"),
    [CT_TOAD] = smlua_model_util_get_id("goomba_trans_geo"),
    [CT_WALUIGI] = smlua_model_util_get_id("goomba_asexual_geo"),
    [CT_WARIO] = smlua_model_util_get_id("goomba_lesbian_geo")
}

excludedActions = {
    [ACT_FLYING] = ACT_FLYING,
    [ACT_WATER_JUMP] = ACT_WATER_JUMP,
    [ACT_HOLD_WATER_JUMP] = ACT_HOLD_WATER_JUMP,
    [ACT_SHOT_FROM_CANNON] = ACT_SHOT_FROM_CANNON,

    [ACT_FORWARD_GROUND_KB] = ACT_FORWARD_GROUND_KB,
    [ACT_BACKWARD_GROUND_KB] = ACT_BACKWARD_GROUND_KB,
    [ACT_SOFT_FORWARD_GROUND_KB] = ACT_SOFT_FORWARD_GROUND_KB,
    [ACT_HARD_BACKWARD_GROUND_KB] = ACT_HARD_BACKWARD_GROUND_KB,

    [ACT_FORWARD_AIR_KB] = ACT_FORWARD_AIR_KB,
    [ACT_BACKWARD_AIR_KB] = ACT_BACKWARD_AIR_KB,
    [ACT_HARD_FORWARD_AIR_KB] = ACT_HARD_FORWARD_AIR_KB,
    [ACT_HARD_BACKWARD_AIR_KB] = ACT_HARD_BACKWARD_AIR_KB
}

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

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

function switch(param, case_table)
    local case = case_table[param]
    if case then return case() end
    local def = case_table['default']
    return def and def() or nil
end

jumpCount = 1
--- @param m MarioState
function mario_update(m)
    if gPlayerSyncTable[m.playerIndex].lgbt then
        obj_set_model_extended(m.marioObj, goombas[m.character.type])
    end

    if m.playerIndex ~= 0 then return end

    if gPlayerSyncTable[0].lgbt then
        switch(m.character.type, {
            [CT_WALUIGI] = function()
                if (m.action == ACT_CROUCHING or m.action == ACT_CROUCH_SLIDE) and (m.controller.buttonDown & Y_BUTTON) ~= 0 then
                    set_mario_action(m, ACT_POWER_JUMP, 0)
                end
            end,
            [CT_WARIO] = function()
                if m.terrainSoundAddend == 0x20000 and m.pos.y < m.waterLevel then -- stepping in water
                    m.health = m.health + 2
                    if m.health > 0x880 then m.health = 0x880 end
                end
            end,
        })
    end
end

--- @param m MarioState
function before_phys_step(m)
    if m.playerIndex ~= 0 or not gPlayerSyncTable[0].lgbt then return end

    if excludedActions[m.action] == nil then
        switch(m.character.type, {
            [CT_MARIO] = function() before_pan_phys_step(m) end,
            [CT_LUIGI] = function() before_bi_phys_step(m) end,
            [CT_TOAD] = function() before_trans_phys_step(m) end,
            [CT_WALUIGI] = function() before_asexual_phys_step(m) end,
            [CT_WARIO] = function() before_lesbian_phys_step(m) end,
        })
    end
end

--- @param m MarioState
function on_player_connected(m)
    gPlayerSyncTable[m.playerIndex].lgbt = false
end


function on_lgbt_command(msg)
    if msg == "off" then
        gPlayerSyncTable[0].lgbt = false
        djui_chat_message_create("LGBT Goombas status: \\#ff0000\\OFF")
    else
        gPlayerSyncTable[0].lgbt = true
        djui_chat_message_create("LGBT Goombas status: \\#00ff00\\ON")
    end
    return true
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)
hook_event(HOOK_ON_PLAYER_CONNECTED, on_player_connected)

hook_chat_command("lgbt", "[on|off] to turn on LGBT goombas", on_lgbt_command)