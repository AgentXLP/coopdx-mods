-- name: PXP
-- description: PXP\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds a custom PVP system written in Lua that overrides the current one, this system is meant to make PVP more customizable

gGlobalSyncTable.bounceBack = false

function if_then_else(cond, if_true, if_false)
    if cond then return if_true end
    return if_false
end

function vec3f_dif(a, b)
    local dest = { x = 0, y = 0, z = 0 }
    dest.x = a.x - b.x
    dest.y = a.y - b.y
    dest.z = a.z - b.z
    return dest
end

function determine_player_damage_value(interaction)
    if (interaction & INT_GROUND_POUND_OR_TWIRL) ~= 0 or (interaction & INT_FAST_ATTACK_OR_SHELL) ~= 0 or (interaction & INT_SLIDE_KICK) ~= 0 then return 3 end
    if (interaction & INT_KICK) ~= 0 then return 2 end

    return 1
end

--- @param m MarioState
function player_is_sliding(m)
    if (m.action & ACT_FLAG_BUTT_OR_STOMACH_SLIDE | ACT_FLAG_DIVING) ~= 0 then return true end
    if m.action == ACT_CROUCH_SLIDE or m.action == ACT_SLIDE_KICK_SLIDE or m.action == ACT_BUTT_SLIDE_AIR or m.action == ACT_HOLD_BUTT_SLIDE_AIR then return true end

    return false
end

--- @param m MarioState
function bounce_back_from_attack(m, interaction)
    if (interaction & (INT_PUNCH | INT_KICK | INT_TRIP)) ~= 0 then
        if m.action == ACT_PUNCHING then
            set_mario_action(m, ACT_MOVE_PUNCHING, 0)
        end

        if (m.action & ACT_FLAG_AIR) ~= 0 then
            mario_set_forward_vel(m, -16.0)
        else
            mario_set_forward_vel(m, -48.0)
        end

        if (m.playerIndex == 0) then set_camera_shake_from_hit(SHAKE_ATTACK) end
        m.particleFlags = m.particleFlags | PARTICLE_TRIANGLE
    end

    if (interaction & (INT_PUNCH | INT_KICK | INT_TRIP | INT_FAST_ATTACK_OR_SHELL)) ~= 0 then
        play_sound(SOUND_ACTION_HIT_2, m.marioObj.header.gfx.cameraToObject)
    end
end

function determine_interacion(m, o)
    local interaction = 0
    local action = m.action

    local dYawToObject = mario_obj_angle_to_object(m, o) - m.faceAngle.y
    dYawToObject = if_then_else(dYawToObject > 32767, dYawToObject - 65536, dYawToObject)
    dYawToObject = if_then_else(dYawToObject < -32768, dYawToObject + 65536, dYawToObject)

    -- hack: make water punch actually do something
    if m.action == ACT_WATER_PUNCH and (o.oInteractType & INTERACT_PLAYER) ~= 0 then
        if -0x2AAA <= dYawToObject and dYawToObject <= 0x2AAA then
            return INT_PUNCH
        end
    end

    if (action & ACT_FLAG_ATTACKING) ~= 0 then
        if action == ACT_PUNCHING or action == ACT_MOVE_PUNCHING or action == ACT_JUMP_KICK then
            if (m.flags & MARIO_PUNCHING) ~= 0 then
                -- 120 degrees total, or 60 each way
                if -0x2AAA <= dYawToObject and dYawToObject <= 0x2AAA then
                    interaction = INT_PUNCH
                end
            end
            if (m.flags & MARIO_KICKING) ~= 0 then
                -- 120 degrees total, or 60 each way
                if -0x2AAA <= dYawToObject and dYawToObject <= 0x2AAA then
                    interaction = INT_KICK
                end
            end
            if (m.flags & MARIO_TRIPPING) ~= 0 then
                -- 180 degrees total, or 90 each way
                interaction = INT_TRIP
            end
        elseif action == ACT_GROUND_POUND or action == ACT_TWIRLING then
            if m.vel.y < 0 then
                interaction = INT_GROUND_POUND_OR_TWIRL
            end
        elseif action == ACT_GROUND_POUND_LAND or action == ACT_TWIRL_LAND then
            -- Neither ground pounding nor twirling change Mario's vertical speed on landing.,
            -- so the speed check is nearly always true (perhaps not if you land while going upwards?)
            -- Additionally, actionState it set on each first thing in their action, so this is
            -- only true prior to the very first frame (i.e. active 1 frame prior to it run).
            if m.vel.y < 0 and m.actionState == 0 then
                interaction = INT_GROUND_POUND_OR_TWIRL
            end
        elseif action == ACT_SLIDE_KICK or action == ACT_SLIDE_KICK_SLIDE then
            interaction = INT_SLIDE_KICK
        elseif (action & ACT_FLAG_RIDING_SHELL) ~= 0 then
            interaction = INT_FAST_ATTACK_OR_SHELL
        elseif m.forwardVel <= -26.0 or 26.0 <= m.forwardVel then
            interaction = INT_FAST_ATTACK_OR_SHELL
        end
    end

    -- Prior to this, the interaction type could be overwritten. This requires, however,
    -- that the interaction not be set prior. This specifically overrides turning a ground
    -- pound into just a bounce.

    if interaction == 0 and (action & ACT_FLAG_AIR) ~= 0 then
        if m.vel.y < 0 then
            if m.pos.y > o.oPosY then
                interaction = INT_HIT_FROM_ABOVE
            end
        else
            if m.pos.y < o.oPosY then
                interaction = INT_HIT_FROM_BELOW
            end
        end
    end

    return interaction
end

--- @param m MarioState
--- @param o Object
function interact_player(m, o, type)
    if type == INTERACT_PLAYER then
        local interaction = determine_interacion(m, o)

        for i = 0, network_player_connected_count() - 1 do
            local m2 = gMarioStates[i]
            local isInCutscene = (m.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE or (m2.action & ACT_GROUP_MASK) == ACT_GROUP_CUTSCENE or m.action == ACT_IN_CANNON or m2.action == ACT_IN_CANNON
            local isInvulnerable = (m2.action & ACT_FLAG_INVULNERABLE) ~= 0 or m2.invincTimer ~= 0 or m2.hurtCounter ~= 0 or isInCutscene
            local isIgnoredAttack = m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP
            local isIgnoredArenaAttack = false

            -- hammer attacks are custom
            if gPlayerSyncTable[m.playerIndex].item == ITEM_HAMMER and mario_hammer_is_attack(m.action) then
                isIgnoredArenaAttack = true
            else
                -- check teams
                isIgnoredArenaAttack = not global_index_hurts_mario_state(gNetworkPlayers[m.playerIndex].globalIndex, m2)
            end

            if o == m2.marioObj and (interaction & INT_ANY_ATTACK) ~= 0 and (interaction & INT_HIT_FROM_ABOVE) == 0 and (interaction & INT_HIT_FROM_BELOW) == 0 and not isInvulnerable and not isIgnoredAttack and not isIgnoredArenaAttack then
                --[[if (interaction & INT_ATTACK_SLIDE) ~= 0 and player_is_sliding(m2) then
                    -- determine the difference in velocities
                    local velDiff = vec3f_dif(m.vel, m2.vel)

                    if vec3f_length(velDiff) < 40 then
                        -- the difference in vectors are not different enough, do not attack
                        return
                    end
                    if (vec3f_length(m2.vel) > vec3f_length(m.vel)) then
                        -- the one being attacked is going faster, do not attack
                        return
                    end
                end]]

                if m.action == ACT_GROUND_POUND then
                    -- not moving down yet?
                    if m.actionState == 0 then return false end
                    m2.squishTimer = math.max(m2.squishTimer, 20)
                end

                m2.interactObj = m.marioObj
                if m2.playerIndex == 0 then m.marioObj.oDamageOrCoinValue = determine_player_damage_value(interaction)
                else m2.marioObj.oDamageOrCoinValue = determine_player_damage_value(interaction) end
                m2.invincTimer = math.max(m2.invincTimer, 3)
                if (interaction & INT_KICK) ~= 0 then
                    if m2.action == ACT_FIRST_PERSON then
                        raise_background_noise(2)
                        set_camera_mode(m2.area.camera, -1, 1)
                        m2.input = m2.input & ~INPUT_FIRST_PERSON
                    end
                    set_mario_action(m2, ACT_FREEFALL, 0)
                end
                if m2.playerIndex == 0 then
                    take_damage_and_knock_back(m2, m.marioObj)
                end
                if gGlobalSyncTable.bounceBack then bounce_back_from_attack(m2, interaction) end
            end
        end
    end
end


function on_bounceback_command(msg)
    if msg == "on" then
        gGlobalSyncTable.bounceBack = true
        djui_chat_message_create("Bounceback status: \\#00FF00\\ON")
    else
        gGlobalSyncTable.bounceBack = false
        djui_chat_message_create("Bounceback status: \\#FF0000\\OFF")
    end
    return true
end

hook_event(HOOK_ALLOW_PVP_ATTACK, function() return false end)
hook_event(HOOK_ON_INTERACT, interact_player)

if network_is_server() then
    hook_chat_command("bounceback", "[on|off] turn on ex-coop's bounce backwards when you hit someone, default is off", on_bounceback_command)
end