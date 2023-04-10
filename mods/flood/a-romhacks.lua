unsupported = true

FLOOD_WATER = 0
FLOOD_LAVA  = 2
FLOOD_SAND  = 3

FLOOD_BONUS_LEVELS = 0
FLOOD_LEVEL_COUNT = 0

LEVEL_LOBBY = LEVEL_CASTLE_GROUNDS
LEVEL_BONUS = LEVEL_PSS

GAME_VANILLA = 0

game = GAME_VANILLA

gLevels = {}
gMapRotation = {}

-- localize functions to improve performance
local table_insert = table.insert
local djui_popup_create = djui_popup_create

local function flood_clear_levels()
    gLevels = {}
    gMapRotation = {}
end
_G.flood_clear_levels = flood_clear_levels

local function flood_define_level(bonus, level, name, goalPos, speed, area, type, starPoints, points, customStartPos)
    if bonus then FLOOD_BONUS_LEVELS = FLOOD_BONUS_LEVELS + 1 end

    if customStartPos ~= nil then
        gLevels[level] = { name = name, goalPos = goalPos, speed = speed, area = area, type = type, time = 0, starPoints = starPoints, points = points, customStartPos = customStartPos }
        table_insert(gMapRotation, level)
    else
        gLevels[level] = { name = name, goalPos = goalPos, speed = speed, area = area, type = type, time = 0, starPoints = starPoints, points = points }
        table_insert(gMapRotation, level)
    end

    FLOOD_LEVEL_COUNT = FLOOD_LEVEL_COUNT + 1
end
_G.flood_define_level = flood_define_level

for mod in pairs(gActiveMods) do
    if gActiveMods[mod].incompatible ~= nil and gActiveMods[mod].incompatible:find("romhack") then
        unsupported = true
        djui_popup_create("\\#ff0000\\This rom hack is not supported with Flood.", 2)
        break
    else
        --                 bonus  level                 name              goal position                                   speed area type         star points points custom start pos
        flood_define_level(false, LEVEL_BOB,            "bob",            { x = 3304,  y = 4242, z = -4603, a =  0x0000 }, 2.5,  1,   FLOOD_WATER, 3,          1,     nil)
        flood_define_level(false, LEVEL_WF,             "wf",             { x = 414,   y = 5325, z = -20,   a =  0x0000 }, 4.0,  1,   FLOOD_WATER, 4,          1,     nil)
        flood_define_level(false, LEVEL_CCM,            "ccm",            { x = -478,  y = 3471, z = -964,  a =  0x0000 }, 5.0,  1,   FLOOD_WATER, 14,         2,     { x = 3336, y = -4200, z = 0, a = 0x0000 })
        flood_define_level(false, LEVEL_BITDW,          "bitdw",          { x = 6772,  y = 2867, z = 0,     a = -0x4000 }, 4.0,  1,   FLOOD_WATER, 10,         3,     nil)
        flood_define_level(false, LEVEL_BBH,            "bbh",            { x = 655,   y = 3277, z = 244,   a =  0x8000 }, 3.5,  1,   FLOOD_WATER, 8,          3,     nil)
        flood_define_level(false, LEVEL_HMC,            "hmc",            { x = -4163, y = 2355, z = -2544, a =  0x0000 }, 3.0,  1,   FLOOD_WATER, 1,          5,     { x = 2546, y = -4279, z = 5579, a = 0x0000 })
        flood_define_level(false, LEVEL_LLL,            "lll",            { x = 2523,  y = 3591, z = -898,  a = -0x8000 }, 3.5,  2,   FLOOD_LAVA,  3,          3,     nil)
        flood_define_level(false, LEVEL_SSL,            "ssl",            { x = 512,   y = 4815, z = -551,  a =  0x0000 }, 3.0,  2,   FLOOD_SAND,  16,         4,     nil)
        flood_define_level(false, LEVEL_WDW,            "wdw",            { x = 1467,  y = 4096, z = 93,    a = -0x4000 }, 4.0,  1,   FLOOD_WATER, 14,         4,     nil)
        flood_define_level(false, LEVEL_TTM,            "ttm",            { x = 1053,  y = 2309, z = 305,   a =  0x0000 }, 3.0,  1,   FLOOD_WATER, 4,          5,     nil)
        flood_define_level(false, LEVEL_THI,            "thi",            { x = 1037,  y = 4060, z = -2091, a =  0x0000 }, 4.0,  1,   FLOOD_WATER, 8,          5,     nil)
        flood_define_level(false, LEVEL_TTC,            "ttc",            { x = 2208,  y = 7051, z = 2217,  a =  0x0000 }, 4.0,  1,   FLOOD_WATER, 3,          7,     nil)
        flood_define_level(false, LEVEL_BITS,           "bits",           { x = 369,   y = 6552, z = -6000, a =  0x0000 }, 4.5,  1,   FLOOD_LAVA,  16,         6,     nil)
        flood_define_level(false, LEVEL_BONUS,          "ctt",            { x = 0,     y = 700,  z = 0,     a =  0x0000 }, 5.0,  1,   FLOOD_LAVA,  0,          6,     nil)
        flood_define_level(true,  LEVEL_SL,             "sl",             { x = 40,    y = 4864, z = 240,   a =  0x0000 }, 3.0,  1,   FLOOD_WATER, 8,          5,     nil)
        flood_define_level(true,  LEVEL_RR,             "rr",             { x = 0,     y = 3468, z = -2335, a =  0x0000 }, 3.0,  1,   FLOOD_WATER, 1,          6,     nil)
        flood_define_level(true,  LEVEL_CASTLE_GROUNDS, "castle_grounds", { x = 0,     y = 7583, z = -4015, a =  0x0000 }, 7.0,  1,   FLOOD_WATER, 0,          9,     nil)
        break
    end
end