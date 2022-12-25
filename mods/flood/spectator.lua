spectator = false
specTarget = 1

function spectate_table()
    local t = {}
    for i = 1, network_player_connected_count() - 1 do
        if gMarioStates[i].action ~= ACT_DEAD and gMarioStates[i].action ~= ACT_DISAPPEARED then
            table.insert(t, gMarioStates[i])
        end
    end
    return t
end

function dead_table()
    local t = {}
    for i = 0, network_player_connected_count() - 1 do
        if gMarioStates[i].action == ACT_DEAD then
            table.insert(t, gMarioStates[i])
        end
    end
    return t
end

--- @param m MarioState
function update_spectator(m)
    spectator = true
    camera_freeze()

    local specTable = spectate_table()
    local specLength = #specTable
    -- buggy
    --[[if specLength > 0 then
        if (m.controller.buttonPressed & L_JPAD) ~= 0 then
            specTarget = specTarget - 1
            if specTarget < 1 then specTarget = specLength end
        elseif (m.controller.buttonPressed & R_JPAD) ~= 0 then
            specTarget = specTarget + 1
            if specTarget > specLength then specTarget = 1 end
        end
    end]]

    local m2 = if_then_else(specLength == 0, dead_table()[1], specTable[specTarget])

    if m2 ~= nil then
        gLakituState.pos.x = m2.pos.x + sins(m2.faceAngle.y) * -1000
        gLakituState.pos.y = m2.pos.y + 500
        gLakituState.pos.z = m2.pos.z + coss(m2.faceAngle.y) * -1000
        vec3f_copy(gLakituState.focus, m2.pos)
    end
    vec3f_copy(m.area.camera.pos, gLakituState.pos)
    vec3f_copy(gLakituState.curPos, gLakituState.pos)
    vec3f_copy(gLakituState.goalPos, gLakituState.pos)
    vec3f_copy(m.area.camera.focus, gLakituState.focus)
    vec3f_copy(gLakituState.curFocus, gLakituState.focus)
    vec3f_copy(gLakituState.goalFocus, gLakituState.focus)
end

function reset_spectator()
    spectator = false
    camera_unfreeze()
end