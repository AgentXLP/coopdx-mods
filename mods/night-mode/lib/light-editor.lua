local dbg = require("dbg")

local gLightEditor = {}

local hide = true
local currLight = 0
local sSavedLights = {}

--- @param id integer
--- @return integer
local function find_prev_light(id)
    if le_get_light_count() == 0 then return -1 end
    if le_get_light_count() == 1 then return 0 end

    local ret = 0
    if id - 1 < 0 then id = LE_MAX_LIGHTS end
    for i = 1, id - 1 do
        if le_light_exists(i) then
            ret = i
        end
    end

    return ret
end

--- @param id integer
--- @return integer
local function find_next_light(id)
    if le_get_light_count() == 0 then return -1 end
    if le_get_light_count() == 1 then return 0 end

    if id + 1 >= LE_MAX_LIGHTS then id = -1 end
    for i = id + 1, LE_MAX_LIGHTS - 1 do
        if le_light_exists(i) then
            return i
        end
    end

    return 0
end

--- @return integer
local function find_any_light()
    for i = 0, LE_MAX_LIGHTS - 1 do
        if le_light_exists(i) then
            return i
        end
    end
    return -1
end

local function clear_saved_lights()
    sSavedLights = {}
end

local function update()
    if hide then return end

    -- render debug information
    for i = 0, LE_MAX_LIGHTS - 1 do
        if not le_light_exists(i) then goto continue end

        local lightPos = gVec3fZero()
        local lightColor = { r = 0, g = 0, b = 0 }
        local lightRadius = le_get_light_radius(i)
        le_get_light_pos(i, lightPos)
        le_get_light_color(i, lightColor)

        local pos = { lightPos.x, lightPos.y, lightPos.z }
        local color = { lightColor.r, lightColor.g, lightColor.b }
        local scale = lightRadius * 0.001
        dbg.point(pos, color, scale)
        pos[2] = pos[2] - 20
        dbg.text("#" .. i, { lightPos.x, lightPos.y - 20, lightPos.z }, color, scale)

        ::continue::
    end

    -- render cached displaylist information
    -- for _, info in ipairs(sCachedDisplaylists) do
    --     dbg.text(info.name, { info.x, info.y, info.z }, { 255, 255, 255 }, 1)
    -- end
end

function gLightEditor.on_hud_render()
    if hide then return end

    --- @type Controller
    local controller = gControllers[0]

    if le_get_light_count() > 0 then
        if (controller.buttonPressed & U_JPAD) ~= 0 then
            currLight = find_prev_light(currLight)
            play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gGlobalSoundSource)
        elseif (controller.buttonPressed & D_JPAD) ~= 0 then
            currLight = find_next_light(currLight)
            play_sound(SOUND_MENU_MESSAGE_NEXT_PAGE, gGlobalSoundSource)
        end
    end

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_SPECIAL)

    djui_hud_set_color(0, 0, 0, 127)
    djui_hud_render_rect(1, 1, 100, 50)

    djui_hud_set_color(255, 255, 255, 255)
    if le_get_light_count() == 0 then
        djui_hud_print_text("No lights in scene.", 2, 0, 0.25)
        return
    end

    if not le_light_exists(currLight) then
        currLight = find_any_light()
    end

    local pos = gVec3fZero()
    le_get_light_pos(currLight, pos)
    local col = { r = 0, g = 0, b = 0 }
    le_get_light_color(currLight, col)

    djui_hud_set_color(col.r, col.g, col.b, 255)
    djui_hud_print_text(string.format("Light (%d)", currLight), 2, 0, 0.25)

    djui_hud_set_color(255, 255, 255, 255)
    local count = tostring(le_get_light_count())
    djui_hud_print_text(count, 99 - djui_hud_measure_text(count) * 0.25, 0, 0.25)
    djui_hud_print_text(string.format("Pos: %d, %d, %d", math.floor(pos.x), math.floor(pos.y), math.floor(pos.z)), 2, 8, 0.25)
    djui_hud_print_text(string.format("Color: %d %d %d", col.r, col.g, col.b), 2, 16, 0.25)
    djui_hud_print_text(string.format("Radius: %.1f", le_get_light_radius(currLight)), 2, 24, 0.25)
    djui_hud_print_text(string.format("Intensity: %.1f", le_get_light_intensity(currLight)), 2, 32, 0.25)
    djui_hud_print_text(string.format("Use Surface Normals: %s", if_then_else(le_get_light_use_surface_normals(currLight), "true", "false")), 2, 40, 0.25)
end

local function on_warp()
    clear_saved_lights()
end


local function on_create_command(msg)
    local values = string.split(msg)
    local posX      = tonumber(values[1]) or math.floor(gMarioStates[0].pos.x)
    local posY      = tonumber(values[2]) or math.floor(gMarioStates[0].pos.y)
    local posZ      = tonumber(values[3]) or math.floor(gMarioStates[0].pos.z)
    local colR      = tonumber(values[4]) or 255
    local colG      = tonumber(values[5]) or 255
    local colB      = tonumber(values[6]) or 255
    local radius    = tonumber(values[7]) or 1000
    local intensity = tonumber(values[8]) or 2.0

    currLight = le_add_light(math.floor(posX), math.floor(posY), math.floor(posZ), colR, colG, colB, radius, intensity)
    table.insert(sSavedLights, currLight)

    djui_chat_message_create("Created light.")
    return true
end

local function on_delete_command()
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    for i, light in ipairs(sSavedLights) do
        if light == currLight then
            table.remove(sSavedLights, i)
        end
    end
    le_remove_light(currLight)

    djui_chat_message_create("Deleted light.")
    return true
end

local function on_pos_command(msg)
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    local values = string.split(msg)
    local posX = math.floor(tonumber(values[1]) or gMarioStates[0].pos.x)
    local posY = math.floor(tonumber(values[2]) or gMarioStates[0].pos.y)
    local posZ = math.floor(tonumber(values[3]) or gMarioStates[0].pos.z)

    le_set_light_pos(currLight, posX, posY, posZ)

    djui_chat_message_create(string.format("Set light position to %d, %d, %d.", posX, posY, posZ))
    return true
end

local function on_col_command(msg)
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    local values = string.split(msg)
    local colR = tonumber(values[1]) or 255
    local colG = tonumber(values[2]) or 255
    local colB = tonumber(values[3]) or 255

    le_set_light_color(currLight, colR, colG, colB)

    djui_chat_message_create(string.format("Set light color to %d, %d, %d.", colR, colG, colB))
    return true
end

local function on_rad_command(msg)
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    local rad = tonumber(msg) or 1000
    le_set_light_radius(currLight, rad)

    djui_chat_message_create(string.format("Set light radius to %d.", rad))
    return true
end

local function on_int_command(msg)
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    local int = tonumber(msg) or 2.0
    le_set_light_intensity(currLight, int)

    djui_chat_message_create(string.format("Set light intensity to %d.", int))
    return true
end

local function on_export_command()
    for _, id in ipairs(sSavedLights) do
        local pos = gVec3fZero()
        le_get_light_pos(id, pos)
        local col = { r = 0, g = 0, b = 0 }
        le_get_light_color(id, col)
        local rad = le_get_light_radius(id)
        local int = le_get_light_intensity(id)
        print(string.format("LIGHT(%d, %d, %d, %d, %d, %d, %d, %d),", pos.x, pos.y, pos.z, col.r, col.g, col.b, rad, int))
    end

    djui_chat_message_create("Exported lights.")
    return true
end

local function on_goto_command()
    if currLight < 0 then
        djui_chat_message_create("\\#ffa0a0\\No light is selected!")
        return true
    end

    local pos = gVec3fZero()
    le_get_light_pos(currLight, pos)
    vec3f_copy(gMarioStates[0].pos, pos)
    djui_chat_message_create("Went to light " .. currLight .. ".")
    return true
end

local function on_ambient_command(msg)
    local values = string.split(msg)
    local colR = tonumber(values[1]) or 255
    local colG = tonumber(values[2]) or 255
    local colB = tonumber(values[3]) or 255

    le_set_ambient_color(colR, colG, colB)

    djui_chat_message_create(string.format("Set ambient color to %d, %d, %d.", colR, colG, colB))
    return true
end

local function on_hide_command()
    hide = not hide
    return true
end

if not init then
    hook_event(HOOK_UPDATE, update)
    hook_event(HOOK_ON_HUD_RENDER, gLightEditor.on_hud_render)
    hook_event(HOOK_ON_WARP, on_warp)

    hook_chat_command("create", "- Creates a light", on_create_command)
    hook_chat_command("delete", "- Deletes a light", on_delete_command)
    hook_chat_command("pos", "- Sets the current light's position", on_pos_command)
    hook_chat_command("col", "- Sets the current light's color", on_col_command)
    hook_chat_command("rad", "- Sets the current light's radius", on_rad_command)
    hook_chat_command("int", "- Sets the current light's intensity", on_int_command)
    hook_chat_command("export", "- Exports a light calls into the console", on_export_command)
    hook_chat_command("goto", "- Set the local player's position to the current light", on_goto_command)
    hook_chat_command("ambient", "- Sets the ambient color", on_ambient_command)
    hook_chat_command("hide", "- Hides or unhides the light editor panel", on_hide_command)
    init = true
end



return gLightEditor