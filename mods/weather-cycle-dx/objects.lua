if not check_dnc_compatible() then return end

-- localize functions to improve performance
local cur_obj_scale,obj_mark_for_deletion,obj_has_model_extended,obj_set_model_extended,vec3f_to_object_pos,calculate_yaw,math_random,maxf,find_water_level,collision_find_ceil,cur_obj_hide,find_floor_height,obj_scale_xyz,obj_set_pos,cur_obj_unhide,spawn_non_sync_object,play_sound,set_camera_shake_from_hit,cur_obj_update_floor_height_and_get_floor,obj_check_hitbox_overlap,set_mario_action,clampf,math_sin = cur_obj_scale,obj_mark_for_deletion,obj_has_model_extended,obj_set_model_extended,vec3f_to_object_pos,calculate_yaw,math.random,maxf,find_water_level,collision_find_ceil,cur_obj_hide,find_floor_height,obj_scale_xyz,obj_set_pos,cur_obj_unhide,spawn_non_sync_object,play_sound,set_camera_shake_from_hit,cur_obj_update_floor_height_and_get_floor,obj_check_hitbox_overlap,set_mario_action,clampf,math.sin

--- @param o Object
function bhv_wc_skybox_init(o)
    o.header.gfx.skipInViewCheck = true
    cur_obj_scale(SKYBOX_SCALE)
end

--- @param o Object
function bhv_wc_skybox_loop(o)
    if not is_wc_enabled() or not show_weather_cycle() then
        obj_mark_for_deletion(o)
        return
    end

    local prevWeather = gWeatherTable[gWeatherState.prevWeatherType]
    local weather = gWeatherTable[gGlobalSyncTable.weatherType]
    if obj_has_model_extended(o, weather.skyboxModel) == 0 and weather.skyboxModel ~= E_MODEL_NONE then
        obj_set_model_extended(o, weather.skyboxModel)
    end
    o.oOpacity = lerp_round(prevWeather.opacity, weather.opacity, gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)

    vec3f_to_object_pos(o, gLakituState.pos)

    o.oFaceAngleYaw = o.oFaceAngleYaw + lerp(prevWeather.skyboxRotSpeed, weather.skyboxRotSpeed, gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
end


function get_rain_droplet_count()
    return lerp_round(gWeatherTable[gWeatherState.prevWeatherType].rainAmount, gWeatherTable[gGlobalSyncTable.weatherType].rainAmount, gWeatherState.transitionTimer / WEATHER_TRANSITION_TIME)
end

--- @param o Object
function bhv_wc_rain_droplet_init(o)
    local weather = gWeatherTable[gGlobalSyncTable.weatherType]
    if not weather.rain then
        obj_mark_for_deletion(o)
        return
    end

    -- SUPER OPTOMIZONÉS! 2000 microseconds to ~600
    local rainYaw = calculate_yaw(gLakituState.pos, gLakituState.focus) + math_random(-0x2000, 0x2000)
    local vel = gMarioStates[0].vel
    local pos = gLakituState.pos

    local posX = pos.x + sins(rainYaw) * math_random(500, 2000) + vel.x * 20
    local posZ = pos.z + coss(rainYaw) * math_random(500, 2000) + vel.z * 20
    local posY = maxf(pos.y, find_water_level(posX, posZ))

    local sanity = 0
    while collision_find_ceil(posX, posY, posZ) ~= nil do
        if sanity == 10 then
            cur_obj_hide()
            o.oAction = 1
            return
        end
        posX = pos.x + sins(rainYaw) * math_random(500, 2000) + vel.x * 20
        posZ = pos.z + coss(rainYaw) * math_random(500, 2000) + vel.z * 20
        sanity = sanity + 1
    end

    o.oAction = 0
    o.oTimer = 0
    o.oFloorHeight = maxf(find_floor_height(posX, posY, posZ), find_water_level(posX, posZ))
    obj_scale_xyz(o, 0.1, weather.rainScaleY, 0.1)
    obj_set_pos(o, posX, posY + math.random(700, 1000), posZ)
    cur_obj_unhide()
end

--- @param o Object
function bhv_wc_rain_droplet_loop(o)
    if not is_wc_enabled() then
        obj_mark_for_deletion(o)
        return
    end

    if o.oAction == 1 then
        bhv_wc_rain_droplet_init(o)
        return
    end

    local weather = gWeatherTable[gGlobalSyncTable.weatherType]
    if not weather.rain then
        weather = gWeatherTable[gWeatherState.prevWeatherType]
        if not weather.rain then
            obj_mark_for_deletion(o)
            return
        end
    end
    o.oPosY = o.oPosY - weather.rainSpeed
    if o.oPosY < o.oFloorHeight then
        for _ = 1, 3 do
            spawn_non_sync_object(
                id_bhvWaterDropletSplash,
                E_MODEL_SMALL_WATER_SPLASH,
                o.oPosX + math.random(-100, 100), o.oFloorHeight, o.oPosZ + math.random(-100, 100),
                nil
            )
        end
        bhv_wc_rain_droplet_init(o)
    end
    if o.oTimer > 40 then
        bhv_wc_rain_droplet_init(o)
    end
end


--- @param o Object
function bhv_wc_lightning_init(o)
    o.header.gfx.skipInViewCheck = true
    local waterLevel = find_water_level(o.oPosX, o.oPosZ)
    if waterLevel ~= gLevelValues.floorLowerLimit and waterLevel > o.oPosY then
        o.oAction = 1 -- indicates this lightning is for the water
        o.oPosY = waterLevel
    end
    play_sound(SOUND_GENERAL2_PYRAMID_TOP_EXPLOSION, gGlobalSoundSource)
    set_camera_shake_from_hit(SHAKE_MED_DAMAGE)
    network_init_object(o, false, {})
end

--- @param o Object
function bhv_wc_lightning_loop(o)
    if in_vanilla_level(LEVEL_SA) then return end

    cur_obj_update_floor_height_and_get_floor()
    -- set the grass on fire
    if o.oTimer == 1 then
        if math.random(0, 1) ~= -1 and o.oFloor ~= nil and (o.oFloorType == SURFACE_NOISE_DEFAULT or o.oFloorType == SURFACE_NOISE_SLIPPERY or o.oFloorType == SURFACE_NOISE_VERY_SLIPPERY) then
            spawn_non_sync_object(
                id_bhvFlameLargeBurningOut,
                E_MODEL_RED_FLAME,
                o.oPosX, o.oPosY, o.oPosZ,
                nil
            )
        end

        spawn_non_sync_object(
            id_bhvExplosion,
            E_MODEL_EXPLOSION,
            o.oPosX, o.oPosY, o.oPosZ,
            nil
        )
    end

    --- @type MarioState
    local m = gMarioStates[0]
    local submerged = (m.action & ACT_GROUP_MASK) == ACT_GROUP_SUBMERGED
    -- checks if the lightning has struck Mario OR has struck the water Mario is swimming in
    if (obj_check_hitbox_overlap(m.marioObj, o) or (o.oAction == 1 and m.waterLevel == o.oPosY and submerged)) and m.hurtCounter == 0 then
        set_mario_action(m, if_then_else(submerged, ACT_WATER_SHOCKED, ACT_SHOCKED), 0)
        play_sound(SOUND_AIR_AMP_BUZZ, m.marioObj.header.gfx.cameraToObject)
        set_camera_shake_from_hit(SHAKE_SHOCK)
        set_camera_shake_from_hit(SHAKE_LARGE_DAMAGE)
        local damage = if_then_else(submerged, 8, 31)
        m.hurtCounter = damage
        gWeatherState.flashTimer = damage
    end
end


--- @param o Object
function bhv_wc_aurora_init(o)
    o.header.gfx.skipInViewCheck = true
end

--- @param o Object
function bhv_wc_aurora_loop(o)
    if not is_wc_enabled() or not show_weather_cycle() then
        obj_mark_for_deletion(o)
        return
    end
    if not gWeatherState.aurora then
        if o.oTimer > 30 then
            o.oTimer = 0
        end

        o.oOpacity = ((30 - o.oTimer) / 30) * 255

        if o.oTimer == 30 then
            obj_mark_for_deletion(o)
        end
        return
    end

    local minutes = _G.dayNightCycleApi.get_time_minutes()
    if minutes > HOUR_SUNRISE_END then
        o.oOpacity = 0
        cur_obj_hide()
        return
    else
        cur_obj_unhide()
    end

    vec3f_to_object_pos(o, gLakituState.pos)
    o.oPosY = o.oPosY + 15000

    if minutes >= HOUR_SUNRISE_START and minutes <= HOUR_SUNRISE_END then
        o.oOpacity = lerp_round(255, 0, clampf((minutes - HOUR_SUNRISE_START) / HOUR_SUNRISE_DURATION, 0, 1))
    elseif minutes >= 0 and minutes <= 1 then
        o.oOpacity = minutes * 255
    elseif minutes > 1 or minutes < HOUR_SUNRISE_START then
        o.oOpacity = 255
    end

    o.oOpacity = clamp(o.oOpacity - 15 - math.sin(o.oTimer * 0.05 * _G.dayNightCycleApi.get_time_scale()) * 15, 0, 255)
end