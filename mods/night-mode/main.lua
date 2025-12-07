-- name: Night Mode
-- incompatible: night-mode light environment-tint
-- description: Night Mode v1.0.1\nBy \\#ec7731\\Agent X\n\n\\#dcdcdc\\This mod adds a night mode to the game in a similar fashion to Day Night\nCycle, however it uses the lighting engine to have realtime point lighting on everything. Press D-Pad down to activate the flashlight, it may look a little janky.\n\nSpecial thanks to MaiskX3 for night time sequences.

-- require("lib/light-editor")

-- localize functions to improve performance
local le_set_ambient_color,set_fog_intensity,set_override_skybox,le_set_light_pos,le_set_light_color,le_set_light_radius,le_set_light_intensity,math_clamp,dist_between_object_and_point,set_override_envfx,audio_stream_get_position,is_game_paused,audio_stream_set_volume,audio_sample_play,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id,spawn_non_sync_object,le_remove_light,obj_mark_for_deletion,obj_set_angle,obj_scale,le_add_light,save_file_get_flags,set_background_music,mod_storage_save_bool,djui_chat_message_create,error,set_override_far,smlua_audio_utils_replace_sequence,smlua_text_utils_course_name_replace,smlua_text_utils_act_name_replace,network_is_server = le_set_ambient_color,set_fog_intensity,set_override_skybox,le_set_light_pos,le_set_light_color,le_set_light_radius,le_set_light_intensity,math.clamp,dist_between_object_and_point,set_override_envfx,audio_stream_get_position,is_game_paused,audio_stream_set_volume,audio_sample_play,obj_get_first_with_behavior_id,obj_get_next_with_same_behavior_id,spawn_non_sync_object,le_remove_light,obj_mark_for_deletion,obj_set_angle,obj_scale,le_add_light,save_file_get_flags,set_background_music,mod_storage_save_bool,djui_chat_message_create,error,set_override_far,smlua_audio_utils_replace_sequence,smlua_text_utils_course_name_replace,smlua_text_utils_act_name_replace,network_is_server

gCoinBhvs = {
    [id_bhvCoinFormationSpawn]    = true,
    [id_bhvYellowCoin]            = true,
    [id_bhvOneCoin]               = true,
    [id_bhvSingleCoinGetsSpawned] = true,
    [id_bhvThreeCoinsSpawn]       = true,
    [id_bhvTenCoinsSpawn]         = true,
}

gGlobalSyncTable.spookyMode = mod_storage_load_bool_2("spooky_mode")

coinLights = true

local function setup_environment()
    if in_vanilla_level(LEVEL_BBH) then
        le_set_ambient_color(0, 0, 0)
    else
        le_set_ambient_color(COLOR_NIGHT.r, COLOR_NIGHT.g, COLOR_NIGHT.b)
    end

    if in_vanilla_level(LEVEL_BOWSER_2) then
        set_fog_color_rgb(0, 0, 0)
    else
        set_fog_color_rgb(50, 50, 100)
    end

    if in_vanilla_level(LEVEL_HMC) then
        set_fog_intensity(0.9)
    elseif in_vanilla_level(LEVEL_SSL) or in_vanilla_level(LEVEL_BOWSER_2) then
        set_fog_intensity(0.96)
    else
        set_fog_intensity(1.0)
    end

    set_lighting_color_rgb(255, 255, 255)
    set_vertex_color_rgb(255, 255, 255)

    -- really don't think I can do Bowser in the Sky justice
    -- with the night time skybox, it just does not fit
    if in_vanilla_level(LEVEL_BITS) or in_vanilla_level(LEVEL_BOWSER_3) then
        set_override_skybox(-1)
    else
        set_override_skybox(BACKGROUND_HAUNTED)
    end
end

local function update()
    local lights = get_map_light_spawn_info()
    if lights ~= nil then
        -- we can always assume these map lights are spawned first before the others
        -- make sure these STAY IN THE POSITIONS THEY WERE ASSIGNED TO.
        -- AND THE PARAMETERS TOO APPARENTLY.
        for i, light in ipairs(lights) do
            le_set_light_pos(i - 1, light.x, light.y, light.z)
            le_set_light_color(i - 1, light.r, light.g, light.b)
            le_set_light_radius(i - 1, light.radius)
            le_set_light_intensity(i - 1, light.intensity)
        end
    end

    if in_vanilla_level(LEVEL_CASTLE) then
        local color = color_lerp(
            COLOR_BLUE,
            COLOR_RED,
            1 - (math_clamp(dist_between_object_and_point(gMarioStates[0].marioObj, -4850, 720, -3670) / 2000, 0, 1))
        )
        le_set_light_color(0, color.r, color.g, color.b)
    elseif in_vanilla_level(LEVEL_BBH) then
        local color = update_rainbow_color(10)
        le_set_light_color(1, color.r, color.g, color.b)
    elseif in_vanilla_level(LEVEL_RR) then
        local color = update_rainbow_color(2)
        le_set_light_color(0, color.r, color.g, color.b)
    end

    if (gMarioStates[0].area.terrainType == TERRAIN_SNOW or in_vanilla_level(LEVEL_LLL) or in_vanilla_level(LEVEL_BITFS)) and gNetworkPlayers[0].currAreaIndex == 1 then
        set_override_envfx(ENVFX_SNOW_BLIZZARD)
    else
        set_override_envfx(ENVFX_MODE_NO_OVERRIDE)
    end

    shading_update()

    -- for spooky mode
    if is_game_paused() and audio_stream_get_position(STREAM_PIANO) > 0 then
        audio_stream_set_volume(STREAM_PIANO, 0)
    end
end

--- @param m MarioState
local function mario_update(m)
    if not active_player(m) then return end

    if m.playerIndex == 0 and (m.controller.buttonPressed & L_JPAD) ~= 0 then
        audio_sample_play(SAMPLE_FLASHLIGHT, m.pos, 1.0)
        gPlayerSyncTable[m.playerIndex].flashlight = not gPlayerSyncTable[m.playerIndex].flashlight
    end

    local globalIndex = gNetworkPlayers[m.playerIndex].globalIndex
    if gPlayerSyncTable[m.playerIndex].flashlight then
        local flashlight = obj_get_first_with_behavior_id(bhvNMFlashlight)
        while flashlight ~= nil do
            if flashlight.globalPlayerIndex == globalIndex then
                return
            end
            flashlight = obj_get_next_with_same_behavior_id(flashlight)
        end

        flashlight = spawn_non_sync_object(
            bhvNMFlashlight,
            E_MODEL_NONE,
            m.pos.x, m.pos.y, m.pos.z,
            nil
        )
        flashlight.globalPlayerIndex = globalIndex
        flashlight.oBehParams = 0xFFFFFFC8
    else
        local flashlight = obj_get_first_with_behavior_id(bhvNMFlashlight)
        while flashlight ~= nil do
            if flashlight.globalPlayerIndex == globalIndex then
                le_remove_light(flashlight.oLightID)
                obj_mark_for_deletion(flashlight)
                return
            end
            flashlight = obj_get_next_with_same_behavior_id(flashlight)
        end
    end
end

local function on_level_init()
    -- setup the environment for every level
    setup_environment()

    -- spawn vanilla level specific objects
    if in_vanilla_level(LEVEL_TTC) then
        local void = spawn_object(id_bhvStaticObject, E_MODEL_NM_TTC_VOID, 0, 500, 0)
        void.header.gfx.skipInViewCheck = true
        obj_set_angle(void, 0x4000, 0, 0)
        obj_scale(void, 0.999)
    elseif in_vanilla_level(LEVEL_BBH) then
        local void = spawn_object(id_bhvStaticObject, E_MODEL_NM_BBH_VOID, 0, 0, 0)
        void.header.gfx.skipInViewCheck = true
        obj_scale(void, 70)
    elseif in_vanilla_level(LEVEL_BOWSER_1) or in_vanilla_level(LEVEL_BOWSER_2) or in_vanilla_level(LEVEL_BOWSER_3) then
        local first = spawn_object(bhvNMBowserLight, E_MODEL_NONE, 0, 2000, 0)
        first.oBehParams = 0x00010000
        first.oBehParams2ndByte = 1

        local second = spawn_object(bhvNMBowserLight, E_MODEL_NONE, 0, 2000, 0)
        second.oBehParams = 0x00020000
        second.oBehParams2ndByte = 2
    end

    spooky_mode_on_level_init()
end

local function on_warp()
    if gMarioStates[0].action == ACT_TELEPORT_FADE_OUT then return end

    setup_environment()

    -- map lights
    local lights = get_map_light_spawn_info()
    if lights ~= nil then
        for _, light in ipairs(lights) do
            le_add_light(light.x, light.y, light.z, light.r, light.g, light.b, light.radius, light.intensity)
        end
    end

    -- TOTWC light
    if in_vanilla_level(LEVEL_CASTLE) and gMarioStates[0].numStars >= gLevelValues.wingCapLookUpReq and
       (save_file_get_flags() & SAVE_FLAG_HAVE_WING_CAP) == 0 and gNetworkPlayers[0].currAreaIndex == 1 then
        local light = le_add_light(-1020, 1070, 400, 255, 255, 255, 5000, 5)
        le_set_light_use_surface_normals(light, false)
    end

    -- LLL music
    if in_vanilla_level(LEVEL_LLL) then
        gMarioStates[0].area.musicParam2 = SEQ_LEVEL_FREEZING
        set_background_music(SEQ_PLAYER_LEVEL, SEQ_LEVEL_FREEZING, 0)
    end
end

--- @param o Object
local function on_object_load(o)
    -- spawn the object light if it exists
    local params = get_object_light_params(o)
    if params == nil then return end

    local light = spawn_object(bhvNMObjectLight, E_MODEL_NONE, o.oPosX, o.oPosY, o.oPosZ)
    light.parentObj = o
    light.oBehParams = params
end

--- @param areaIndex integer
local function on_instant_warp(areaIndex)
    if gNetworkPlayers[0].currAreaIndex ~= areaIndex then
        on_warp()
    end
end


--- @param value boolean
local function on_set_spooky_mode(_, value)
    gGlobalSyncTable.spookyMode = value
    mod_storage_save_bool("spooky_mode", value)
    djui_chat_message_create("[Night Mode] You need to restart the level for changes to take effect.")
end

--- @param value boolean
local function on_set_coin_lights(_, value)
    coinLights = value
end

local sReadonlyMetatable = {
    __index = function(table, key)
        return rawget(table, key)
    end,

    __newindex = function()
        error("Attempt to update a read-only table", 2)
    end
}

_G.nightModeApi = {
    version = NM_VERSION,
    LIGHT = LIGHT,
}
setmetatable(_G.nightModeApi, sReadonlyMetatable)

set_override_far(20000)

le_set_mode(LE_MODE_AFFECT_ALL_SHADED_AND_COLORED)
le_set_tone_mapping(LE_TONE_MAPPING_TOTAL_WEIGHTED)

smlua_audio_utils_replace_sequence(SEQ_LEVEL_GRASS, 42, 70, "night_level_grass")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_INSIDE_CASTLE, 42, 70, "night_level_inside_castle")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_WATER, 42, 70, "night_level_water")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_HOT, 42, 70, "night_level_hot")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_SNOW, 42, 70, "night_level_snow")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_SLIDE, 42, 70, "night_level_slide")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_UNDERGROUND, 42, 70, "night_level_underground")
smlua_audio_utils_replace_sequence(SEQ_LEVEL_FREEZING, 37, 70, "night_level_freezing")

smlua_text_utils_course_name_replace(COURSE_LLL, "Lethal Ice Land")
smlua_text_utils_act_name_replace(COURSE_LLL, 1, "Freeze The Big Bully")
smlua_text_utils_act_name_replace(COURSE_LLL, 4, "Ice-Cold Log Rolling")
smlua_text_utils_act_name_replace(COURSE_LLL, 5, "Cold-Foot-It Into The Volcano")

smlua_text_utils_course_name_replace(COURSE_BITFS, "Bowser in the Ice Sea")

-- behold! my weirdest hack yet
-- set the vertex colors of various vertex buffers found in LLL, BITFS, and Bowser 2 from red to blue
freeze_lava_dl("lll_seg7_dl_0701A1F0", 8, 3)
freeze_lava_dl("bitfs_seg7_dl_0700FD08", 9, 3)
freeze_lava_dl("bitfs_seg7_dl_07011568", 8, 8)
freeze_lava_dl("bitfs_seg7_dl_07011318", 12, 3)
freeze_lava_dl("bowser_2_seg7_dl_07000FE0", 15, 3)
freeze_lava_dl("bowser_2_seg7_dl_07000FE0", 16, 3)
freeze_lava_dl("bowser_2_seg7_dl_07000FE0", 17, 3)
freeze_lava_dl("bowser_2_seg7_dl_07001930", 15, 10)
freeze_lava_dl("bowser_2_seg7_dl_07001930", 15, 17)
freeze_lava_dl("bowser_2_seg7_dl_07001930", 15, 24)

nullify_dl_alpha(gfx_get_from_name("bbh_seg7_dl_0700D7E0"))

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ON_OBJECT_LOAD, on_object_load)
hook_event(HOOK_ON_INSTANT_WARP, on_instant_warp)

if network_is_server() then
    hook_mod_menu_checkbox("Spooky Mode", gGlobalSyncTable.spookyMode, on_set_spooky_mode)
end

hook_mod_menu_checkbox("Coin Lights", coinLights, on_set_coin_lights)

for i = 0, MAX_PLAYERS - 1 do
    gPlayerSyncTable[i].flashlight = false
end