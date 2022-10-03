-- name: Everyone Wins
-- description: Everyone Wins\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod makes it so everyone in the Bowser 3 fight will enter the jumbo cutscene when the grand star is collected.

--- @param m MarioState
function mario_update(m)
    if gNetworkPlayers[0].currLevelNum ~= LEVEL_BOWSER_3 or m.playerIndex == 0 or gMarioStates[0].action == ACT_JUMBO_STAR_CUTSCENE then return end

    if m.action == ACT_JUMBO_STAR_CUTSCENE then set_mario_action(gMarioStates[0], ACT_JUMBO_STAR_CUTSCENE, 0) end
end

hook_event(HOOK_MARIO_UPDATE, mario_update)