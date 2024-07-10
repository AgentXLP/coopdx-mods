--- @param cond boolean
--- Human readable ternary operator
function if_then_else(cond, ifTrue, ifFalse)
    if cond then return ifTrue end
    return ifFalse
end

--- @param m MarioState
--- Checks if a player is currently active
function active_player(m)
    local np = gNetworkPlayers[m.playerIndex]
    if m.playerIndex == 0 then
        return true
    end
    if not np.connected then
        return false
    end
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then
        return false
    end
    if np.currActNum ~= gNetworkPlayers[0].currActNum then
        return false
    end
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then
        return false
    end
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then
        return false
    end
    return true
end

--- @param reliable boolean
--- @param packet integer
--- @param dataTable table
--- Sends a packet with the level, area, and act it came from
function packet_send(reliable, packet, dataTable)
    dataTable = dataTable or {}
    dataTable.id = packet
    dataTable.level = gNetworkPlayers[0].currLevelNum
    dataTable.area = gNetworkPlayers[0].currAreaIndex
    dataTable.act = gNetworkPlayers[0].currActNum
    network_send(reliable, dataTable)
end

function tobool(v)
    local type = type(v)
    if type == "boolean" then
        return v
    elseif type == "number" then
        return v == 1
    elseif type == "string" then
        return v == "true"
    end
    return nil
end