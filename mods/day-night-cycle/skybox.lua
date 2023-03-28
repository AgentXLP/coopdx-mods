local SKYBOX_DAY = 0
local SKYBOX_SUNSET = 1
local SKYBOX_NIGHT = 2

local E_MODEL_CLEAR = smlua_model_util_get_id("clear_geo")
local E_MODEL_SKYBOX_SUNSET = smlua_model_util_get_id("skybox_sunset_geo")
local E_MODEL_SKYBOX_NIGHT = smlua_model_util_get_id("skybox_night_geo")

local gVanillaSkyboxModels = {
    [BACKGROUND_OCEAN_SKY] = smlua_model_util_get_id("skybox_ocean_sky_geo"),
    [BACKGROUND_FLAMING_SKY] = smlua_model_util_get_id("skybox_flaming_sky_geo"),
    [BACKGROUND_UNDERWATER_CITY] = smlua_model_util_get_id("skybox_underwater_city_geo"),
    [BACKGROUND_BELOW_CLOUDS] = smlua_model_util_get_id("skybox_below_clouds_geo"),
    [BACKGROUND_SNOW_MOUNTAINS] = smlua_model_util_get_id("skybox_snow_mountains_geo"),
    [BACKGROUND_DESERT] = smlua_model_util_get_id("skybox_desert_geo"),
    [BACKGROUND_HAUNTED] = smlua_model_util_get_id("skybox_haunted_geo"),
    [BACKGROUND_GREEN_SKY] = smlua_model_util_get_id("skybox_green_sky_geo"),
    [BACKGROUND_ABOVE_CLOUDS] = smlua_model_util_get_id("skybox_above_clouds_geo"),
    [BACKGROUND_PURPLE_SKY] = smlua_model_util_get_id("skybox_purple_sky_geo")
}

-- localize functions to improve performance
local vec3f_to_object_pos = vec3f_to_object_pos
local obj_mark_for_deletion = obj_mark_for_deletion
local obj_scale = obj_scale
local clampf = clampf
local get_skybox = get_skybox
local set_override_far = set_override_far
local obj_get_first_with_behavior_id = obj_get_first_with_behavior_id
local obj_set_model_extended = obj_set_model_extended
local spawn_non_sync_object = spawn_non_sync_object
local lerp = lerp

--- @param o Object
local function bhv_skybox_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.header.gfx.skipInViewCheck = true
    o.oFaceAngleYaw = 0
    o.oFaceAngleRoll = 0
    o.oFaceAnglePitch = 0
    o.oOpacity = 255

    set_override_far(100000)
end

--- @param o Object
local function bhv_skybox_loop(o)
    vec3f_to_object_pos(o, gLakituState.pos)

    if get_skybox() == -1 then
        obj_mark_for_deletion(o)
        return
    end
    if o.oBehParams2ndByte > 2 then return end

    local minutes = (gGlobalSyncTable.time / MINUTE) % 24

    if get_skybox() ~= BACKGROUND_GREEN_SKY then
        if o.oBehParams2ndByte ~= SKYBOX_SUNSET then
            o.oFaceAngleYaw = o.oFaceAngleYaw + 4 * gGlobalSyncTable.timeScale
        else
            if minutes < 12 then
                o.oFaceAngleYaw = 0
            else
                o.oFaceAngleYaw = 0x8000
            end
        end
    end

    if o.oBehParams2ndByte == SKYBOX_DAY then
        obj_set_model_extended(o, gVanillaSkyboxModels[get_skybox()])

        if minutes >= 6 and minutes <= 7 then
            o.oOpacity = lerp(0, 255, clampf((minutes - 6), 0, 1))
        elseif minutes >= 18 and minutes <= 19 then
            o.oOpacity = lerp(255, 0, clampf((minutes - 18), 0, 1))
        end
        if minutes < 6 or minutes > 20 then
            o.oOpacity = 0
        elseif minutes > 7 and minutes < 18 then
            o.oOpacity = 255
        end

        if gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] then
            o.oOpacity = 255
        end
    elseif o.oBehParams2ndByte == SKYBOX_SUNSET then
        if minutes >= 5 and minutes <= 6 then
            o.oOpacity = lerp(0, 255, clampf((minutes - 5), 0, 1))
        elseif minutes >= 6 and minutes <= 7 then
            o.oOpacity = lerp(255, 0, clampf((minutes - 6), 0, 1))
        elseif minutes >= 18 and minutes <= 19 then
            o.oOpacity = lerp(0, 255, clampf((minutes - 18), 0, 1))
        elseif minutes >= 19 and minutes <= 20 then
            o.oOpacity = lerp(255, 0, clampf((minutes - 19), 0, 1))
        else
            o.oOpacity = 0
        end
    elseif o.oBehParams2ndByte == SKYBOX_NIGHT then
        if minutes >= 5 and minutes <= 6 then
            o.oOpacity = lerp(255, 0, clampf((minutes - 5), 0, 1))
        elseif minutes >= 19 and minutes <= 20 then
            o.oOpacity = lerp(0, 255, clampf((minutes - 19), 0, 1))
        end
        if minutes > 6 and minutes < 19 then
            o.oOpacity = 0
        elseif minutes > 20 or minutes < 5 then
            o.oOpacity = 255
        end
    end
end

local id_bhvSkybox = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_skybox_init, bhv_skybox_loop)

local function update()
    if obj_get_first_with_behavior_id(id_bhvSkybox) == nil and get_skybox() ~= -1 then
        -- black cube that renders on the background layer over the vanilla skybox hiding it simulating a kind of graphics clear color effect
        spawn_non_sync_object(
            id_bhvSkybox,
            E_MODEL_CLEAR,
            0, 0, 0,
            --- @param o Object
            function(o)
                o.oBehParams2ndByte = 3
            end
        )
        -- spawn day, sunset and night skyboxes
        for i = 0, 2 do
            if not gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] or i == 0 then
                local model = 0
                if i == 0 then
                    model = gVanillaSkyboxModels[get_skybox()]
                else
                    model = if_then_else(i == 1, E_MODEL_SKYBOX_SUNSET, E_MODEL_SKYBOX_NIGHT)
                end
                spawn_non_sync_object(
                    id_bhvSkybox,
                    model,
                    0, 0, 0,
                    --- @param o Object
                    function(o)
                        o.oBehParams2ndByte = i
                        obj_scale(o, 200 + (10 * i))
                    end
                )
            end
        end
    end
end

hook_event(HOOK_UPDATE, update)