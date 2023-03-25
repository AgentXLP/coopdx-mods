-- name: Easy Ceiling Cling
-- description: Easy Ceiling Cling\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds improved ceiling hang detection system so you can now begin clinging to ceiling from actions outside\nof just the single and double jump.

--- @param m MarioState
local function before_phys_step(m)
    if m.ceil ~= nil and m.ceil.type == SURFACE_HANGABLE and (m.action == ACT_TRIPLE_JUMP or m.action == ACT_WALL_KICK_AIR) then
        if m.pos.y + 180 > m.ceil.lowerY then
            set_mario_action(m, ACT_START_HANGING, 0)
        end
    end
end

hook_event(HOOK_BEFORE_PHYS_STEP, before_phys_step)