--- @param o Object
function bhv_galaxy_act_selector_star_init(o)
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oFaceAngleYaw = o.oFaceAngleYaw + 0x8000
    o.oStarSelectorSize = 3
end

--- @param o Object
function bhv_galaxy_act_selector_star_loop(o)
    o.oFaceAngleRoll = o.oFaceAngleRoll + 0x600

    if sStarSelectHUD.selectedStar == o.oBehParams2ndByte then
        if sStarSelectHUD.starSelected then
            o.oPosX = approach_number(o.oPosX, 0, 20, 20)

            if o.oPosX == 0 then
                o.oFaceAngleRoll = o.oFaceAngleRoll + 0x800
                o.oStarSelectorSize = approach_number(o.oStarSelectorSize, 3, 0.09, 0.09)
                if o.oAction == 0 then
                    play_character_sound(gMarioStates[0], CHAR_SOUND_LETS_A_GO)
                    play_djui_transition(false, 30, 255, 255, 255)
                    o.oAction = 1
                else
                    if sDjuiTransition.fadeAlpha == 255 then
                        warp_to_level(sStarSelectHUD.targetLevel, sStarSelectHUD.targetArea, sStarSelectHUD.selectedStar)
                        play_djui_transition(true, 30, 255, 255, 255)
                    end
                end
            else
                o.oStarSelectorSize = approach_number(o.oStarSelectorSize, 1.75, 0.09, 0.09)
            end
        else
            o.oStarSelectorSize = approach_number(o.oStarSelectorSize, 1.75, 0.09, 0.09)
        end
    else
        local scale = 0
        if not sStarSelectHUD.starSelected then
            if o.oBehParams2ndByte == 7 then
                scale = 0.75
            else
                scale = 1
            end
        end

        o.oStarSelectorSize = approach_number(o.oStarSelectorSize, scale, 0.09, 0.09)
    end

    obj_scale(o, o.oStarSelectorSize)
end

id_bhvGalaxyActSelectorStar = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_galaxy_act_selector_star_init, bhv_galaxy_act_selector_star_loop)

--- @param o Object
function bhv_galaxy_act_selector_init(o)
    local stars = save_file_get_star_flags(get_current_save_file_num() - 1, level_to_course(sStarSelectHUD.targetLevel) - 1)

    -- the first 6 stars
    for i = 0, 5 do
        local model = if_then_else((stars & (1 << i)) ~= 0, E_MODEL_STAR, E_MODEL_TRANSPARENT_STAR)
        sStarSelectHUD.stars[i + 1] = spawn_non_sync_object(
            id_bhvGalaxyActSelectorStar,
            model,
            500 - (i * 200), 0, 0,
            --- @param obj Object
            function(obj)
                obj.oBehParams2ndByte = i + 1
            end
        )
    end

    -- 100 coin star
    if (stars & (1 << 6)) ~= 0 then
        spawn_non_sync_object(
            id_bhvGalaxyActSelectorStar,
            E_MODEL_STAR,
            0, -130, 0,
            --- @param obj Object
            function(obj)
                obj.oBehParams2ndByte = 7
            end
        )
    end
end

--- @param o Object
function bhv_galaxy_act_selector_loop(o)
    --- @type MarioState
    local m = gMarioStates[0]

    if not sStarSelectHUD.starSelected then
        sStarSelectHUD.timeSinceMovedStick = sStarSelectHUD.timeSinceMovedStick + 1
        -- hack
        if m.controller.rawStickX < 4 and m.controller.rawStickX > -4 then
            sStarSelectHUD.timeSinceMovedStick = 7
        end
        if sStarSelectHUD.timeSinceMovedStick >= 7 then
            if m.controller.rawStickX > 60 then
                if sStarSelectHUD.selectedStar < 6 then
                    sStarSelectHUD.selectedStar = sStarSelectHUD.selectedStar + 1
                    play_sound(SOUND_MENU_CHANGE_SELECT, { x = 0, y = 0, z = 0 })
                end
                sStarSelectHUD.timeSinceMovedStick = 0
            elseif m.controller.rawStickX < -60 then
                if sStarSelectHUD.selectedStar > 1 then
                    sStarSelectHUD.selectedStar = sStarSelectHUD.selectedStar - 1
                    play_sound(SOUND_MENU_CHANGE_SELECT, { x = 0, y = 0, z = 0 })
                end
                sStarSelectHUD.timeSinceMovedStick = 0
            end
        end
    end

    local stars = save_file_get_star_flags(get_current_save_file_num() - 1, level_to_course(sStarSelectHUD.targetLevel) - 1)
    if ((stars & (1 << sStarSelectHUD.selectedStar - 2)) ~= 0 or (stars & (1 << sStarSelectHUD.selectedStar - 1)) ~= 0 or sStarSelectHUD.selectedStar == 1) and (m.controller.buttonPressed & (A_BUTTON | B_BUTTON | START_BUTTON)) ~= 0 and not sStarSelectHUD.starSelected and sStarSelectHUD.topBarY == 0 then
        sStarSelectHUD.starSelected = true
        play_sound(SOUND_MENU_STAR_SOUND, { x = 0, y = 0, z = 0 })
    end
end

id_bhvGalaxyActSelector = hook_behavior(nil, OBJ_LIST_DEFAULT, true, bhv_galaxy_act_selector_init, bhv_galaxy_act_selector_loop)