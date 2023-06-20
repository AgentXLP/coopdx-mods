-- name: Achievements Demo
-- description: Achievements\nBy \\#ec7731\\Agent X\\#dcdcdc\\\n\nThis mod adds savable achievements to sm64ex-coop. There are 10 achievements so far in this demo to collect over the game, two requiring the use of bugs.\nThe achievements menu is in the pause menu, use DPad Left and DPad Right to\ncycle through achievements.

ACHIEVEMENT_FIRST_STAR = 0
ACHIEVEMENT_HUNDRED_COINS = 1
ACHIEVEMENT_BOMB_CLIP = 2
ACHIEVEMENT_WING_CAP = 3
ACHIEVEMENT_METAL_CAP = 4
ACHIEVEMENT_VANISH_CAP = 5
ACHIEVEMENT_CASTLE_CLIMBER = 6
ACHIEVEMENT_COLLECTOR = 7
ACHIEVEMENT_TRADITIONAL = 8
ACHIEVEMENT_SPEEDRUNNER = 9

ACHIEVEMENT_MAX = 10

gAchievements = {
    [ACHIEVEMENT_FIRST_STAR] = {
        name = "Stars' In The Bag",
        description = "Snatch the first star before anyone else can.",
        lines = 4
    },
    [ACHIEVEMENT_HUNDRED_COINS] = {
        name = "Self Proclaimed Millionare",
        description = "Obtain 100 coins in a level.",
        lines = 3
    },
    [ACHIEVEMENT_BOMB_CLIP] = {
        name = "Gate Clipper",
        description = "Get the star behind the Chain Chomp without ground pounding its pole.",
        lines = 5
    },
    [ACHIEVEMENT_WING_CAP] = {
        name = "Wing Mario To The Sky!",
        description = "Unlock the Wing Cap.",
        lines = 3
    },
    [ACHIEVEMENT_METAL_CAP] = {
        name = "Solid Steel",
        description = "Unlock the Metal Cap.",
        lines = 3
    },
    [ACHIEVEMENT_VANISH_CAP] = {
        name = "Father Figure",
        description = "Unlock the Vanish Cap.",
        lines = 3
    },
    [ACHIEVEMENT_CASTLE_CLIMBER] = {
        name = "Castle Climber",
        description = "Get on top of the castle before obtaining 120 stars.",
        lines = 4
    },
    [ACHIEVEMENT_COLLECTOR] = {
        name = "Collector's Prize",
        description = "Collect 120 stars.",
        lines = 3
    },
    [ACHIEVEMENT_TRADITIONAL] = {
        name = "A Traditional Victory",
        description = "Beat the game with a star count above or at 70.",
        lines = 4
    },
    [ACHIEVEMENT_SPEEDRUNNER] = {
        name = "A Speedrunners' Victory",
        description = "Beat the game with a star count below 70.",
        lines = 4
    }
}

for k, v in pairs(gAchievements) do
    v.unlocked = false
    local achievement = mod_storage_load(k .. "_unlocked")
    if achievement == nil then
        mod_storage_save(k .. "_unlocked", "false")
    else
        v.unlocked = achievement == "true"
    end
end

prevNumStars = 0
prevNumCoins = 0

function total_unlocked_achievements()
    local count = 0
    for k, v in pairs(gAchievements) do
        if v.unlocked then count = count + 1 end
    end
    return count
end

function achievement_unlock(id)
    local achievement = gAchievements[id]
    if achievement == nil then return end
    if not achievement.unlocked then
        achievement.unlocked = true
        mod_storage_save(id .. "_unlocked", "true")

        play_sound(SOUND_GENERAL2_RIGHT_ANSWER, { x = 0, y = 0, z = 0 })
        djui_popup_create(string.format("\\#00ff00\\Achievement Unlocked\\#dcdcdc\\ (%s/%s): %s\n%s", total_unlocked_achievements(), ACHIEVEMENT_MAX, achievement.name, achievement.description), achievement.lines)

        spawn_non_sync_object(id_bhvSparkleParticleSpawner, E_MODEL_SPARKLES, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z, nil)
        spawn_non_sync_object(id_bhvSparkleParticleSpawner, E_MODEL_SPARKLES, gMarioStates[0].pos.x, gMarioStates[0].pos.y, gMarioStates[0].pos.z, nil)

        if total_unlocked_achievements() == ACHIEVEMENT_MAX then
            play_secondary_music(SEQ_EVENT_CUTSCENE_COLLECT_KEY, 0, 80, 15)
        end
    end
end

function update()
    --- @type MarioState
    local m = gMarioStates[0]

    if prevNumCoins ~= m.numCoins then
        prevNumCoins = m.numCoins
    end
    if prevNumStars ~= m.numStars then
        -- free 120 star achievement for everyone
        if m.numStars == 120 and prevNumStars ~= 0 then
            achievement_unlock(ACHIEVEMENT_COLLECTOR)
        end

        prevNumStars = m.numStars
    end

    -- is mario in ending cutscene for achievement
    if m.action == ACT_JUMBO_STAR_CUTSCENE then
        if m.numStars < 70 then
            achievement_unlock(ACHIEVEMENT_SPEEDRUNNER)
        else
            achievement_unlock(ACHIEVEMENT_TRADITIONAL)
        end
    end

    -- is mario on cap switch for achievement
    if m.marioObj.platform ~= nil and get_id_from_behavior(m.marioObj.platform.behavior) == id_bhvCapSwitch and m.marioObj.platform.oAction == 1 then
        local capAchievements = { [0] = ACHIEVEMENT_WING_CAP, [1] = ACHIEVEMENT_METAL_CAP, [2] = ACHIEVEMENT_VANISH_CAP }
        achievement_unlock(capAchievements[m.marioObj.platform.oBehParams2ndByte])
    end

    -- is mario on top of castle for achievement
    if gNetworkPlayers[0].currLevelNum == LEVEL_CASTLE_GROUNDS and m.numStars < 120 and ((m.pos.y > 2238 and m.floor.normal.y > 0.99) or m.pos.y > 3173) and m.pos.y == m.floorHeight then
        achievement_unlock(ACHIEVEMENT_CASTLE_CLIMBER)
    end
end

selectedAchievement = 0
function on_hud_render()
    if not is_game_paused() then return end

    --- @type MarioState
    local m = gMarioStates[0]

    djui_hud_set_resolution(RESOLUTION_N64)
    djui_hud_set_font(FONT_NORMAL)

    local width = djui_hud_get_screen_width()

    -- cycle through achievements and loop around
    if (m.controller.buttonPressed & L_JPAD) ~= 0 then
        selectedAchievement = selectedAchievement - 1
        if selectedAchievement < 0 then
            selectedAchievement = ACHIEVEMENT_MAX - 1
        end
    elseif (m.controller.buttonPressed & R_JPAD) ~= 0 then
        selectedAchievement = selectedAchievement + 1
        if selectedAchievement > ACHIEVEMENT_MAX - 1 then
            selectedAchievement = 0
        end
    end

    local achievement = gAchievements[selectedAchievement]
    local text = tostring(achievement.name) .. string.format(" (%s/%s)", selectedAchievement + 1, ACHIEVEMENT_MAX)
    local scale = 0.5

    djui_hud_set_color(0, 0, 0, 127)
    djui_hud_render_rect(50, 18, width - 100, 60)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(text, width * 0.5 - (djui_hud_measure_text(text) * 0.5 * scale), 25, scale)
    scale = 0.3
    text = achievement.description
    djui_hud_print_text(text, width * 0.5 - (djui_hud_measure_text(text) * 0.5 * scale), 40, scale)

    scale = 0.75
    if achievement.unlocked then
        djui_hud_set_color(0, 255, 0, 255)
        text = "UNLOCKED"
    else
        djui_hud_set_color(255, 0, 0, 255)
        text = "LOCKED"
    end
    djui_hud_print_text(text, width * 0.5 - (djui_hud_measure_text(text) * 0.5 * scale), 50, scale)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(math.floor((total_unlocked_achievements() / ACHIEVEMENT_MAX) * 100) .. "%", 53, 55, 0.37)
    djui_hud_print_text(string.format("%s/%s Unlocked", total_unlocked_achievements(), ACHIEVEMENT_MAX), 53, 65, 0.37)
end

--- @param m MarioState
--- @param o Object
function on_interact(m, o, type, value)
    if type == INTERACT_STAR_OR_KEY and get_id_from_behavior(o.behavior) == id_bhvStar then
        if m.numStars == 1 and prevNumStars ~= 1 then
            achievement_unlock(ACHIEVEMENT_FIRST_STAR)
        end

        -- mario can clip through the gate with a box or bomb
        if gNetworkPlayers[0].currLevelNum == LEVEL_BOB and o.oBehParams >> 24 == 5 and obj_get_first_with_behavior_id(id_bhvChainChompGate) ~= nil then
            achievement_unlock(ACHIEVEMENT_BOMB_CLIP)
        end
    elseif type == INTERACT_COIN then
        if m.numCoins >= 100 and prevNumCoins < 100 then
            achievement_unlock(ACHIEVEMENT_HUNDRED_COINS)
        end
    end
end

hook_event(HOOK_UPDATE, update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_ON_INTERACT, on_interact)