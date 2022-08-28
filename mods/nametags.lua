-- name: Nametags
-- description: Nametags\nBy \\#ec7731\\Agent X\\#ffffff\\\n\nThis mod adds nametags to sm64ex-coop, a long awaited feature that will ultimately never be added.

function clamp(x, a, b)
    if x < a then return a end
    if x > b then return b end
    return x
end

--- @param m MarioState
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
    return is_player_active(m)
end

function djui_hud_set_adjusted_color(r, g, b, a)
    local multiplier = 1
    if is_game_paused() then multiplier = 0.5 end
    djui_hud_set_color(r * multiplier, g * multiplier, b * multiplier, a)
end

function djui_hud_print_outlined_text(text, x, y, scale, r, g, b, outlineDarkness)
    -- render outline
    djui_hud_set_adjusted_color(r * outlineDarkness, g * outlineDarkness, b * outlineDarkness, 255)
    djui_hud_print_text(text, x - (1*(scale*2)), y, scale)
    djui_hud_print_text(text, x + (1*(scale*2)), y, scale)
    djui_hud_print_text(text, x, y - (1*(scale*2)), scale)
    djui_hud_print_text(text, x, y + (1*(scale*2)), scale)
    -- render text
    djui_hud_set_adjusted_color(r, g, b, 255)
    djui_hud_print_text(text, x, y, scale)
    djui_hud_set_color(255, 255, 255, 255)
end

function name_and_hex(name)
    local nameTable = {}
    name:gsub(".", function(c) table.insert(nameTable, c) end)

    local removed = false
    local color = "000000"
    for k, v in pairs(nameTable) do
        if v == "\\" and not removed then
            removed = true
            nameTable[k] = ""     -- \
            nameTable[k + 1] = "" -- #
            if nameTable[k + 2] ~= nil and nameTable[k + 3] ~= nil and nameTable[k + 4] ~= nil and nameTable[k + 5] ~= nil and nameTable[k + 6] ~= nil and nameTable[k + 7] ~= nil then
                color = nameTable[k + 2] .. nameTable[k + 3] .. nameTable[k + 4] .. nameTable[k + 5] .. nameTable[k + 6] .. nameTable[k + 7]
            end
            nameTable[k + 2] = "" -- f
            nameTable[k + 3] = "" -- f
            nameTable[k + 4] = "" -- f
            nameTable[k + 5] = "" -- f
            nameTable[k + 6] = "" -- f
            nameTable[k + 7] = "" -- f
            nameTable[k + 8] = "" -- \
        end
    end
    return { name = table.concat(nameTable, ""), color = color }
end

function hex_to_rgb(hex)
    local hexTable = {}
    hex:gsub("..", function(c) table.insert(hexTable, c) end)
    return { r = tonumber(hexTable[1], 16), g = tonumber(hexTable[2], 16), b = tonumber(hexTable[3], 16) }
end

function on_hud_render()
    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    for i = 1, network_player_connected_count() - 1 do
        local m = gMarioStates[i]
        if dist_between_objects(gMarioStates[0].marioObj, m.marioObj) > 2000 then return end
        if active_player(m) then
            local out = { x = 0, y = 0, z = 0 }
            local pos = { x = m.pos.x, y = m.marioBodyState.headPos.y + 120, z = m.pos.z }
            djui_hud_world_pos_to_screen_pos(pos, out)

            local scale = 0.5
            if m.playerIndex ~= 0 then
                scale = 0.25
                scale = scale + dist_between_objects(gMarioStates[0].marioObj, m.marioObj) / 3000
                scale = clamp(1 - scale, 0, 0.5)
            end
            local info = name_and_hex(gNetworkPlayers[i].name)
            local color = { r = 162, g = 202, b = 234 }
            if info.color ~= "000000" then color = hex_to_rgb(info.color) end
            local measure = djui_hud_measure_text(info.name) * 0.5 * scale
            djui_hud_print_outlined_text(info.name, out.x - measure, out.y, scale, color.r, color.g, color.b, 0.25)
        end
    end
end

hook_event(HOOK_ON_HUD_RENDER, on_hud_render)