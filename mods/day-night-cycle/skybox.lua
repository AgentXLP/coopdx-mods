if VERSION_NUMBER < 35 then return end

local SKYBOX_DAY = 0
local SKYBOX_SUNSET = 1
local SKYBOX_NIGHT = 2

local E_MODEL_CLEAR = smlua_model_util_get_id("clear_geo")

-- standard skyboxes
local E_MODEL_SKYBOX_OCEAN_SKY = smlua_model_util_get_id("skybox_ocean_sky_geo")
local E_MODEL_SKYBOX_FLAMING_SKY = smlua_model_util_get_id("skybox_flaming_sky_geo")
local E_MODEL_SKYBOX_UNDERWATER_CITY = smlua_model_util_get_id("skybox_underwater_city_geo")
local E_MODEL_SKYBOX_BELOW_CLOUDS = smlua_model_util_get_id("skybox_below_clouds_geo")
local E_MODEL_SKYBOX_SNOW_MOUNTAINS = smlua_model_util_get_id("skybox_snow_mountains_geo")
local E_MODEL_SKYBOX_DESERT = smlua_model_util_get_id("skybox_desert_geo")
local E_MODEL_SKYBOX_HAUNTED = smlua_model_util_get_id("skybox_haunted_geo")
local E_MODEL_SKYBOX_GREEN_SKY = smlua_model_util_get_id("skybox_green_sky_geo")
local E_MODEL_SKYBOX_ABOVE_CLOUDS = smlua_model_util_get_id("skybox_above_clouds_geo")
local E_MODEL_SKYBOX_PURPLE_SKY = smlua_model_util_get_id("skybox_purple_sky_geo")
local E_MODEL_SKYBOX_NIGHT = smlua_model_util_get_id("skybox_night_geo")
local E_MODEL_SKYBOX_SUNRISE = smlua_model_util_get_id("skybox_sunrise_geo")
local E_MODEL_SKYBOX_SUNSET = smlua_model_util_get_id("skybox_sunset_geo")

-- below clouds skyboxes
local E_MODEL_SKYBOX_BELOW_CLOUDS_NIGHT = smlua_model_util_get_id("skybox_below_clouds_night_geo")
local E_MODEL_SKYBOX_BELOW_CLOUDS_SUNRISE = smlua_model_util_get_id("skybox_below_clouds_sunrise_geo")
local E_MODEL_SKYBOX_BELOW_CLOUDS_SUNSET = smlua_model_util_get_id("skybox_below_clouds_sunset_geo")

local gVanillaSkyboxModels = {
    [BACKGROUND_OCEAN_SKY] = E_MODEL_SKYBOX_OCEAN_SKY,
    [BACKGROUND_FLAMING_SKY] = E_MODEL_SKYBOX_FLAMING_SKY,
    [BACKGROUND_UNDERWATER_CITY] = E_MODEL_SKYBOX_UNDERWATER_CITY,
    [BACKGROUND_BELOW_CLOUDS] = E_MODEL_SKYBOX_BELOW_CLOUDS,
    [BACKGROUND_SNOW_MOUNTAINS] = E_MODEL_SKYBOX_SNOW_MOUNTAINS,
    [BACKGROUND_DESERT] = E_MODEL_SKYBOX_DESERT,
    [BACKGROUND_HAUNTED] = E_MODEL_SKYBOX_HAUNTED,
    [BACKGROUND_GREEN_SKY] = E_MODEL_SKYBOX_GREEN_SKY,
    [BACKGROUND_ABOVE_CLOUDS] = E_MODEL_SKYBOX_ABOVE_CLOUDS,
    [BACKGROUND_PURPLE_SKY] = E_MODEL_SKYBOX_PURPLE_SKY
}

-- localize functions to improve performance
local set_override_far,vec3f_to_object_pos,get_skybox,obj_mark_for_deletion,obj_set_model_extended,clampf,network_is_server,djui_hud_is_pause_menu_created,obj_get_first_with_behavior_id,spawn_non_sync_object,obj_scale = set_override_far,vec3f_to_object_pos,get_skybox,obj_mark_for_deletion,obj_set_model_extended,clampf,network_is_server,djui_hud_is_pause_menu_created,obj_get_first_with_behavior_id,spawn_non_sync_object,obj_scale

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

    -- do not run any code if the skybox is not a day, sunset or night skybox
    if o.oBehParams2ndByte > 2 then return end

    local minutes = (gGlobalSyncTable.time / MINUTE) % 24

    -- do not rotate BITDW skybox
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
        obj_set_model_extended(o, gVanillaSkyboxModels[get_skybox()] or E_MODEL_SKYBOX_OCEAN_SKY)

        if minutes >= HOUR_SUNRISE_END and minutes <= HOUR_DAY_START then
            o.oOpacity = lerp(0, 255, clampf((minutes - HOUR_SUNRISE_END) / HOUR_SUNSET_DURATION, 0, 1))
        elseif minutes >= HOUR_SUNSET_START and minutes <= HOUR_SUNSET_END then
            o.oOpacity = lerp(255, 0, clampf((minutes - HOUR_SUNSET_START) / HOUR_SUNSET_DURATION, 0, 1))
        end
        if minutes < HOUR_SUNRISE_END or minutes > HOUR_NIGHT_START then
            o.oOpacity = 0
        elseif minutes > HOUR_DAY_START + 1 and minutes < HOUR_SUNSET_START then
            o.oOpacity = 255
        end

        if gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] and not romhack then
            o.oOpacity = 255
        end
    elseif o.oBehParams2ndByte == SKYBOX_SUNSET then
        if minutes >= HOUR_SUNRISE_START and minutes <= HOUR_SUNRISE_END then
            o.oOpacity = lerp(0, 255, clampf((minutes - HOUR_SUNRISE_START) / HOUR_SUNRISE_DURATION, 0, 1))
        elseif minutes >= HOUR_SUNRISE_END and minutes <= HOUR_DAY_START then
            o.oOpacity = lerp(255, 0, clampf((minutes - HOUR_SUNRISE_END) / HOUR_SUNRISE_DURATION, 0, 1))
        elseif minutes >= HOUR_SUNSET_START and minutes <= HOUR_SUNSET_END then
            o.oOpacity = lerp(0, 255, clampf((minutes - HOUR_SUNSET_START) / HOUR_SUNSET_DURATION, 0, 1))
        elseif minutes >= HOUR_SUNSET_END and minutes <= HOUR_NIGHT_START then
            o.oOpacity = lerp(255, 0, clampf((minutes - HOUR_SUNSET_END) / HOUR_SUNSET_DURATION, 0, 1))
        else
            o.oOpacity = 0
        end

        if get_skybox() == BACKGROUND_BELOW_CLOUDS then
            if minutes < 12 then
                obj_set_model_extended(o, E_MODEL_SKYBOX_BELOW_CLOUDS_SUNRISE)
            else
                obj_set_model_extended(o, E_MODEL_SKYBOX_BELOW_CLOUDS_SUNSET)
            end
        else
            if minutes < 12 then
                obj_set_model_extended(o, E_MODEL_SKYBOX_SUNRISE)
            else
                obj_set_model_extended(o, E_MODEL_SKYBOX_SUNSET)
            end
        end
    elseif o.oBehParams2ndByte == SKYBOX_NIGHT then
        if minutes >= HOUR_SUNRISE_START and minutes <= HOUR_SUNRISE_END then
            o.oOpacity = lerp(255, 0, clampf((minutes - HOUR_SUNRISE_START) / HOUR_SUNRISE_DURATION, 0, 1))
        elseif minutes >= HOUR_SUNSET_END and minutes <= HOUR_NIGHT_START then
            o.oOpacity = lerp(0, 255, clampf((minutes - HOUR_SUNSET_END) / HOUR_SUNSET_DURATION, 0, 1))
        end
        if minutes > HOUR_SUNRISE_END and minutes < HOUR_SUNSET_END then
            o.oOpacity = 0
        elseif minutes > HOUR_NIGHT_START or minutes < HOUR_SUNRISE_START then
            o.oOpacity = 255
        end

        if get_skybox() == BACKGROUND_BELOW_CLOUDS then
            obj_set_model_extended(o, E_MODEL_SKYBOX_BELOW_CLOUDS_NIGHT)
        else
            obj_set_model_extended(o, E_MODEL_SKYBOX_NIGHT)
        end
    end
end

local id_bhvSkybox = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_skybox_init, bhv_skybox_loop)

local function update()
    if not _G.DayNightCycle.enabled then return end

    -- increment time serversided, autosave as well
    if network_is_server() then
        gGlobalSyncTable.time = gGlobalSyncTable.time + gGlobalSyncTable.timeScale

        autoSaveTimer = (autoSaveTimer + 1) % (SECOND * 30)
        if autoSaveTimer == 0 then
            save_time()
        end

        if djui_hud_is_pause_menu_created() then
            if not saved then
                save_time()
                saved = true
            end
        else
            saved = false
        end
    end

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
            if not gExcludedDayNightLevels[gNetworkPlayers[0].currLevelNum] or i == 0 or romhack then
                local model = 0
                if i == 0 then
                    model = gVanillaSkyboxModels[get_skybox()] or E_MODEL_SKYBOX_OCEAN_SKY
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