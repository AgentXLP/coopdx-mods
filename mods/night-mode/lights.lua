--- @class Light
--- @field public x number
--- @field public y number
--- @field public z number
--- @field public r integer
--- @field public g integer
--- @field public b integer
--- @field public radius number
--- @field public intensity number

-- localize functions to improve performance
local level_is_vanilla_level,get_id_from_behavior,le_set_light_pos,le_set_light_color,le_set_light_radius,le_set_light_intensity = level_is_vanilla_level,get_id_from_behavior,le_set_light_pos,le_set_light_color,le_set_light_radius,le_set_light_intensity

local gLightData = {}

--- @param x number
--- @param y number
--- @param z number
--- @param r integer
--- @param g integer
--- @param b integer
--- @param radius number
--- @param intensity number
--- Macro for map light entries
function LIGHT(x, y, z, r, g, b, radius, intensity)
    return { x = x, y = y, z = z, r = r, g = g, b = b, radius = radius, intensity = intensity }
end

--- @type Light[][]
gLightData.mapLights = {
    [LEVEL_CASTLE_GROUNDS] = {
        {
            LIGHT(0, 1000, -2870, 255, 255, 255, 1000, 2), -- entrance light
        }
    },
    [LEVEL_CASTLE] = {
        { -- main floor
            LIGHT(-7050, 1070, -5860, 255, 0, 0, 5000, 10), -- BITDW warp
            LIGHT(-5030, 630, -460, 255, 255, 255, 1000, 10), -- BOB painting
            LIGHT(-2300, -90, -3850, 255, 255, 255, 1000, 10), -- CCM painting
            LIGHT(250, 50, -4160, 255, 255, 255, 1000, 10), -- WF painting
            LIGHT(4120, 540, -240, 0, 200, 255, 1000, 5), -- JRB painting
            LIGHT(1630, 880, -2430, 255, 255, 255, 600, 5), -- PSS warp
            LIGHT(-1100, -750, 1180, 255, 50, 0, 500, 5), -- basement light

            LIGHT(2725, 540, 1220, 255, 255, 255, 1000, 5), -- JRB light 1
            LIGHT(3690, 540, 765, 255, 255, 255, 1000, 5), -- JRB light 2
            LIGHT(3710, 540, -1190, 255, 255, 255, 1000, 5), -- JRB light 3
            LIGHT(2775, 540, -1670, 255, 255, 255, 1000, 5), -- JRB light 4
        },
        { -- upstairs
            LIGHT(-630, 1530, 30, 255, 255, 255, 1000, 5), -- WDW painting
            LIGHT(-690, 1410, 3732, 255, 255, 255, 1000, 5), -- TTM painting
            LIGHT(-4810, 1410, 2820, 255, 255, 255, 1000, 5), -- THI painting 1
            LIGHT(-4770, 2210, -2700, 255, 255, 255, 5000, 5), -- THI painting 2
            LIGHT(-6850, 1650, 1780, 255, 255, 255, 1500, 5), -- THI fake painting
            LIGHT(3560, 1710, -130, 255, 255, 255, 1000, 5), -- SL painting
            LIGHT(5130, 1710, 45, 255, 255, 255, 1000, 5), -- SL mirror painting
            LIGHT(-240, 2830, 7040, 255, 255, 255, 1000, 5), -- TTC painting
            LIGHT(3000, 3150, 5905, 255, 255, 255, 2000, 5), -- RR warp
            LIGHT(-2415, 3150, 5895, 255, 255, 255, 1500, 5), -- WMOTR warp
            LIGHT(-202, 3374, 4569, 255, 255, 255, 1000, 2), -- endless stairs door light
            LIGHT(-195, 3930, 2710, 255, 0, 0, 1500, 5), -- endless stairs light 1
            LIGHT(-250, 5450, -3270, 255, 0, 0, 2000, 5), -- endless stairs light 2
        },
        { -- basement
            LIGHT(-1400, -800, -3500, 0, 200, 255, 1500, 20), -- LLL painting
            LIGHT(2500, -1000, -2600, 0, 127, 0, 1600, 5), -- HMC painting
            LIGHT(5080, -720, 2000, 30, 30, 255, 5000, 10), -- DDD painting

            LIGHT(1500, -800, -500, 255, 255, 255, 1500, 2), -- moat light
        },
    },
    [LEVEL_BOB] = {
        {
            LIGHT(1360, 4500, -5600, 255, 255, 255, 1000, 5), -- mountain light 1
            LIGHT(2975, 4500, -6560, 255, 255, 255, 1000, 5), -- mountain light 2
            LIGHT(4770, 4500, -5615, 255, 255, 255, 1000, 5), -- mountain light 3
            LIGHT(3110, 4500, -3150, 255, 255, 255, 1000, 5), -- mountain light 4
            LIGHT(1370, 4500, -3575, 255, 255, 255, 1000, 5), -- mountain light 5
        },
    },
    [LEVEL_CCM] = {
        {
            LIGHT(-4720, -1000, 1800, 0, 255, 0, 1000, 2), -- snowman light
            LIGHT(-934, -3224, 6471, 255, 127, 0, 2000, 5), -- pink bob-omb island light
        },
        {
            LIGHT(-5535, 6915, -6100, 255, 127, 0, 1500, 5), -- entrance light
            LIGHT(-6485, -5565, -6960, 255, 127, 0, 1000, 5), -- exit light
            LIGHT(-6415, -4065, -6340, 255, 0, 0, 1500, 2), -- slide skip light 1
            LIGHT(-4880, 2345, -720, 255, 0, 0, 1000, 5), -- slide skip light 2
            LIGHT(-4905, -455, 6635, 255, 0, 0, 2000, 5), -- slide skip light 3
            LIGHT(-6420, -1495, 3550, 255, 0, 0, 1000, 5), -- slide skip light 4
            LIGHT(-7855, -1175, 6030, 255, 0, 0, 2000, 2), -- slide skip light 5
        },
    },
    [LEVEL_PSS] = {
        {
            LIGHT(2932, 6374, -5626, 255, 127, 0, 1000, 2), -- lamp light 1
            LIGHT(-3597, 4854, -5699, 255, 127, 0, 1000, 2), -- lamp light 2
            LIGHT(-5510, 4694, -5165, 255, 127, 0, 1000, 2), -- lamp light 3
            LIGHT(-6434, 4294, -3116, 255, 127, 0, 1000, 2), -- lamp light 4
            LIGHT(-6351, 3894, -38, 255, 127, 0, 1000, 2), -- lamp light 5
            LIGHT(-4975, 3494, 2088, 255, 127, 0, 1000, 2), -- lamp light 6
            LIGHT(-6365, -3906, 1206, 255, 127, 0, 2000, 2), -- lamp light 7
            LIGHT(-6373, -4066, 2497, 255, 127, 0, 2000, 2), -- lamp light 8
            LIGHT(-6409, -4186, 3882, 255, 127, 0, 2000, 2), -- lamp light 9
        },
    },
    [LEVEL_TOTWC] = {
        {
            LIGHT(0, 0, 0, 255, 0, 0, 10000, 1) -- main light
        },
    },
    [LEVEL_VCUTM] = {
        {
            LIGHT(0, 3000, 0, 0, 0, 255, 10000, 1) -- main light
        },
    },
    [LEVEL_BBH] = {
        {
            LIGHT(-2630, -45, 5060, 255, 255, 50, 1500, 2), -- house light
            LIGHT(-140, -1945, 80, 255, 0, 0, 2000, 5), -- merry go round light
            LIGHT(-295, 1220, 2440, 255, 255, 50, 1000, 5), -- exterior window light 1
            LIGHT(-295, 300, 2440, 255, 255, 50, 1000, 5), -- exterior window light 2
            LIGHT(1650, 1240, 2500, 255, 255, 50, 1000, 5), -- exterior window light 3
            LIGHT(1650, 320, 2500, 255, 255, 50, 1000, 5), -- exterior window light 4
            LIGHT(-1530, 1220, 2950, 255, 255, 50, 1000, 5), -- exterior window light 5
            LIGHT(-1530, 300, 2950, 255, 255, 50, 1000, 5), -- exterior window light 6
            LIGHT(2860, 320, 2950, 255, 255, 50, 1000, 5), -- exterior window light 7
            LIGHT(2860, 1240, 2950, 255, 255, 50, 1000, 5), -- exterior window light 8
            LIGHT(-1600, 260, -1760, 255, 127, 0, 1000, 5), -- exterior window light 9
            LIGHT(-111, 2418, 686, 255, 255, 50, 1000, 5), -- interior window light 1
            LIGHT(1448, 2418, 780, 255, 255, 50, 1000, 5), -- interior window light 2
            LIGHT(-111, 2418, 686, 255, 255, 50, 1000, 5), -- interior light 1
            LIGHT(1448, 2418, 780, 255, 255, 50, 1000, 5), -- interior light 2
            LIGHT(435, 340, 200, 255, 255, 50, 1000, 2), -- interior light 3
            LIGHT(1610, 340, 280, 255, 255, 50, 1000, 2), -- interior light 4
            LIGHT(200, 340, 640, 255, 255, 50, 1000, 2), -- interior light 5
            LIGHT(190, 340, 1480, 255, 255, 50, 1000, 2), -- interior light 6
            LIGHT(1870, 340, 1485, 255, 255, 50, 1000, 2), -- interior light 7
            LIGHT(960, 300, 1080, 255, 255, 50, 1700, 2), -- interior light 8
            LIGHT(-70, 1220, 510, 255, 255, 50, 1000, 2), -- interior light 9
            LIGHT(1820, 1220, 230, 255, 255, 50, 1000, 2), -- interior light 10
            LIGHT(-1550, 380, 2000, 255, 255, 50, 500, 2) -- piano room light
        },
    },
    [LEVEL_HMC] = {
        {
            LIGHT(-5800, 2030, 715, 255, 127, 0, 1500, 5), -- rolling rocks room light 1
            LIGHT(-4130, 2030, -530, 255, 127, 0, 1500, 5), -- rolling rocks room light 2
            LIGHT(-5900, 2030, -3530, 255, 127, 0, 1500, 5), -- rolling rocks room light 3
            LIGHT(-6050, 2100, -5320, 255, 127, 0, 1500, 5), -- rolling rocks room light 4
            LIGHT(-6065, 2340, -6760, 255, 127, 0, 1500, 5), -- rolling rocks room light 5
            LIGHT(-5180, 3140, -7960, 255, 127, 0, 1500, 5), -- rolling rocks room light 6
            LIGHT(-7137, 2041, 254, 255, 127, 0, 1500, 5), -- rolling rocks room light 7
            LIGHT(-3270, 0, -6810, 255, 127, 0, 2000, 10), -- underground lake elevator light
            LIGHT(-3600, -1900, 3600, 255, 255, 200, 5000, 10), -- underground lake main light
            LIGHT(-1940, -4540, 130, 255, 127, 0, 3000, 10), -- underground lake lamp light 1
            LIGHT(-5120, -4540, 64, 255, 127, 0, 3000, 10), -- underground lake lamp light 2
            LIGHT(2150, -4240, 2350, 255, 127, 0, 1500, 10), -- underground lake lamp light 3
            LIGHT(3769, -4180, 2333, 255, 127, 0, 1500, 10), -- underground lake lamp light 4
            LIGHT(5140, -4240, 2290, 255, 127, 0, 1500, 10), -- underground lake lamp light 5
            LIGHT(-7459, 2778, 7427, 255, 255, 50, 1000, 5), -- spawn lamp light 1
            LIGHT(-4753, 2641, 6477, 255, 255, 50, 1000, 5), -- spawn lamp light 2
            LIGHT(-6578, 2521, 4663, 255, 255, 50, 1000, 5), -- spawn lamp light 3
            LIGHT(-6516, 2241, 2629, 255, 255, 50, 1000, 5), -- spawn lamp light 4
            LIGHT(-3081, 2658, 4938, 255, 255, 50, 1000, 5), -- spawn lamp light 5
            LIGHT(-2021, 2658, 4031, 255, 255, 50, 1000, 5), -- spawn lamp light 6
            LIGHT(-30, 2498, 3672, 255, 255, 50, 1000, 5), -- spawn lamp light 7
            LIGHT(1144, 420, 3565, 255, 255, 50, 1000, 5), -- red coin room lamp light 1
            LIGHT(597, 420, 2503, 255, 255, 50, 1000, 5), -- red coin room lamp light 2
            LIGHT(-1299, 440, 1075, 255, 255, 50, 1000, 5), -- red coin room lamp light 3
            LIGHT(-5933, 2918, 5941, 255, 255, 255, 1000, 10), -- map light 1
            LIGHT(-4400, 2840, -3145, 255, 255, 255, 1000, 10), -- map light 2
            LIGHT(2042, 660, 2668, 255, 255, 255, 1000, 10), -- map light 3
            LIGHT(1966, -404, -1730, 0, 255, 0, 1000, 2), -- poison gas light 1
            LIGHT(2854, -404, -2840, 0, 255, 0, 1000, 2), -- poison gas light 2
            LIGHT(3943, -603, -4059, 0, 255, 0, 1000, 2), -- poison gas light 3
            LIGHT(3938, -603, -2833, 0, 255, 0, 1000, 2), -- poison gas light 4
            LIGHT(1956, -283, -4685, 0, 255, 0, 1000, 2), -- poison gas light 5
            LIGHT(5739, -389, -1784, 0, 255, 0, 1000, 2), -- poison gas light 6
            LIGHT(5701, -489, -4712, 0, 255, 0, 1000, 2), -- poison gas light 7
            LIGHT(3392, -423, -5682, 0, 255, 0, 2000, 2), -- poison gas light 8
            LIGHT(4396, -609, -341, 0, 255, 0, 2000, 2), -- poison gas light 9
            LIGHT(3376, -4442, 4769, 0, 255, 0, 2000, 2), -- metal cap light
        },
    },
    [LEVEL_COTMC] = {
        {
            LIGHT(0, 900, -2300, 0, 255, 0, 10000, 2) -- main light
        },
    },
    [LEVEL_SSL] = {
        {
            LIGHT(683, 660, 6566, 255, 255, 50, 1000, 2), -- spawn light
        },
        {
            LIGHT(12, 498, 3305, 255, 255, 50, 2000, 2), -- interior light 1
            LIGHT(1176, 2178, -32, 255, 255, 50, 5000, 2), -- interior light 2
        },
        nil,
    },
    [LEVEL_LLL] = {
        {
            LIGHT(0, 2000, 0, 50, 200, 255, 10000, 10), -- blue light
        },
        {
            LIGHT(0, 6700, 0, 50, 200, 255, 10000, 10), -- blue light
        },
    },
    [LEVEL_DDD] = {
        {
            LIGHT(3926+8192, 2476, 5257, 255, 255, 50, 3000, 2), -- ceiling light 1
            LIGHT(4126+8192, 2461, -2900, 255, 255, 50, 3000, 2), -- ceiling light 2
            LIGHT(5818+8192, 2461, -439, 255, 255, 50, 3000, 2), -- ceiling light 3
            LIGHT(5656+8192, 2461, 3180, 255, 255, 50, 3000, 2), -- ceiling light 4
            LIGHT(1816+8192, 2433, 3174, 255, 255, 50, 3000, 2), -- ceiling light 5
            LIGHT(1933+8192, 2489, -1775, 255, 255, 50, 3000, 2), -- ceiling light 6
        },
        {
            LIGHT(3926, 2476, 5257, 255, 255, 50, 3000, 2), -- ceiling light 1
            LIGHT(4126, 2461, -2900, 255, 255, 50, 3000, 2), -- ceiling light 2
            LIGHT(5818, 2461, -439, 255, 255, 50, 3000, 2), -- ceiling light 3
            LIGHT(5656, 2461, 3180, 255, 255, 50, 3000, 2), -- ceiling light 4
            LIGHT(1816, 2433, 3174, 255, 255, 50, 3000, 2), -- ceiling light 5
            LIGHT(1933, 2489, -1775, 255, 255, 50, 3000, 2), -- ceiling light 6
        },
    },
    [LEVEL_BITFS] = {
        {
            LIGHT(0, -1000, 0, 50, 200, 255, 5000, 10), -- main light 1
            LIGHT(0, 2000, 0, 50, 200, 255, 5000, 10), -- main light 2
            LIGHT(0, 5000, 0, 50, 200, 255, 5000, 10), -- main light 3
            LIGHT(-5000, -1000, 0, 50, 200, 255, 5000, 10), -- main light 4
            LIGHT(5000, -1000, 0, 50, 200, 255, 5000, 10), -- main light 5
            LIGHT(-5000, 2000, 0, 50, 200, 255, 5000, 10), -- main light 6
            LIGHT(5000, 2000, 0, 50, 200, 255, 5000, 10), -- main light 7
            LIGHT(5000, 5000, 0, 50, 200, 255, 5000, 10), -- main light 8
            LIGHT(-5000, 5000, 0, 50, 200, 255, 5000, 10), -- main light 9
        },
    },
    [LEVEL_SL] = {
        {
            LIGHT(378, 2362, -4578, 50, 200, 255, 3000, 10), -- chilly bully arena light
            LIGHT(432, 2556, 1361, 255, 255, 255, 1000, 2), -- igloo light
        },
        {
            LIGHT(8, 122, 1025, 255, 255, 255, 5000, 2), -- room light
        },
    },
    [LEVEL_TTM] = {
        {
            LIGHT(3133, -1339, 3725, 255, 127, 0, 5000, 5), -- waterfall light 1
            LIGHT(2280, 1897, 1809, 255, 127, 0, 2000, 5), -- waterfall light 2
        },
        {
            LIGHT(4351, 4121, 1043, 127, 127, 255, 10000, 2), -- symbol light 1
            LIGHT(-959, 3041, 2342, 255, 255, 50, 10000, 2), -- symbol light 2
            LIGHT(-2504, 1841, -465, 255, 255, 50, 10000, 2), -- symbol light 3
            LIGHT(-115, 1561, -3909, 255, 255, 50, 10000, 2), -- symbol light 4
        },
        {
            LIGHT(4351+10240, 4121+7168, 1043+10240, 127, 127, 255, 10000, 2), -- symbol light 1
            LIGHT(-959+10240, 3041+7168, 2342+10240, 255, 255, 50, 10000, 2), -- symbol light 2
            LIGHT(-2504+10240, 1841+7168, -465+10240, 255, 255, 50, 10000, 2), -- symbol light 3
            LIGHT(-115+10240, 1561+7168, -3909+10240, 255, 255, 50, 10000, 2), -- symbol light 4
            LIGHT(-5136, 5833, 9389, 127, 127, 255, 10000, 2), -- symbol light 5
            LIGHT(-8966, 4773, 5336, 255, 255, 50, 10000, 2), -- symbol light 6
            LIGHT(-8326, 1253, -6730, 255, 255, 50, 10000, 2), -- symbol light 7
            LIGHT(1303, -787, -4905, 255, 0, 0, 3000, 5), -- skull light
            LIGHT(-1819, -4766, 7152, 255, 255, 50, 10000, 0), -- symbol light 8
        },
        {
            LIGHT(10793, 3035, 506, 255, 255, 50, 10000, 2), -- symbol light 1
            LIGHT(5132, 2235, -7932, 255, 255, 50, 10000, 2), -- symbol light 2
            LIGHT(216, 2235, -1507, 255, 255, 50, 10000, 2), -- symbol light 3
        },
    },
    [LEVEL_THI] = {
        {
            LIGHT(-1, 4070, -1540, 255, 255, 255, 1000, 2), -- mountain light
        },
        {
            LIGHT(-10, 1167, -460, 255, 255, 255, 1000, 2), -- mountain light
        },
        {
            LIGHT(0, 2920, 0, 255, 255, 255, 5000, 2), -- beams of light 1
            LIGHT(517, 1060, 2024, 255, 255, 255, 5000, 2), -- beams of light 2
        },
    },
    [LEVEL_RR] = {
        {
            LIGHT(0, 0, 0, 255, 255, 255, 10000, 1), -- map light
            LIGHT(-4190, 3269, -6402, 255, 0, 0, 2000, 5), -- fire light
            LIGHT(5287, 4969, 593, 255, 255, 255, 2000, 10), -- rainbow light 1
            LIGHT(4983, 2289, 241, 255, 255, 255, 2000, 10), -- rainbow light 2
            LIGHT(5082, 1129, 263, 255, 255, 255, 2000, 10), -- rainbow light 3
            LIGHT(1042, 1289, -325, 255, 255, 255, 2000, 10), -- rainbow light 4
            LIGHT(3335, 1189, -1625, 255, 255, 255, 2000, 10), -- rainbow light 5
            LIGHT(5458, 869, -3144, 255, 255, 255, 2000, 10), -- rainbow light 6
            LIGHT(3952, -391, -3747, 255, 255, 255, 2000, 10), -- rainbow light 7
            LIGHT(2181, -391, -3687, 255, 255, 255, 2000, 10), -- rainbow light 8
            LIGHT(-1316, 2349, -158, 255, 255, 255, 2000, 10), -- rainbow light 9
            LIGHT(-2979, 4227, -330, 255, 255, 255, 2000, 10), -- rainbow light 10
            LIGHT(-2627, 4229, -2429, 255, 255, 255, 2000, 10), -- rainbow light 11
            LIGHT(-1436, 4069, -4037, 255, 255, 255, 2000, 10), -- rainbow light 12
            LIGHT(-4200, 3589, -5182, 255, 255, 255, 2000, 10), -- rainbow light 13
            LIGHT(-3834, 5509, -5101, 255, 255, 255, 2000, 10), -- rainbow light 14
            LIGHT(5531, -1373, 2128, 255, 255, 255, 2000, 10), -- rainbow light 15
            LIGHT(7466, -573, 1069, 255, 255, 255, 2000, 10), -- rainbow light 16
            LIGHT(4988, -493, -56, 255, 255, 255, 2000, 10), -- rainbow light 17
            LIGHT(2360, 2867, 153, 255, 255, 255, 2000, 10), -- rainbow light 18
            LIGHT(-5195, 4067, -1760, 255, 255, 255, 2000, 10), -- rainbow light 19
            LIGHT(-7480, 4627, -2926, 255, 255, 255, 2000, 10), -- rainbow light 20
            LIGHT(-7302, 5107, -5112, 255, 255, 255, 2000, 10), -- rainbow light 21
            -- LIGHT(-3549, -814, 4984, 255, 255, 255, 2000, 5), -- general light 1
            -- LIGHT(-2193, -2654, 6524, 255, 255, 255, 2000, 5), -- general light 2
            -- LIGHT(607, -3034, 6559, 255, 255, 255, 2000, 5), -- general light 3
            -- LIGHT(-6012, -2434, 6590, 255, 255, 255, 2000, 5), -- general light 4
            -- LIGHT(5115, 4926, 3424, 255, 255, 255, 2000, 5), -- general light 5
            -- LIGHT(2669, -1014, 1978, 255, 255, 255, 2000, 5), -- general light 6
            -- LIGHT(5975, -294, 6441, 255, 255, 255, 3000, 5), -- general light 7
            -- LIGHT(608, -1574, 4088, 255, 255, 255, 2000, 5), -- general light 8
        },
    },
    [LEVEL_WMOTR] = {
        {
            LIGHT(0, 5000, 0, 150, 220, 255, 20000, 10), -- main light
        },
    },
    [LEVEL_BITS] = {
        {
            LIGHT(-6000, 0, 0, 200, 50, 255, 10000, 20), -- main light 1
            LIGHT(6000, 0, 0, 127, 255, 0, 10000, 10), -- main light 2
            LIGHT(0, 7200, -5900, 200, 50, 255, 1500, 5), -- pipe light 1
            LIGHT(800, 7200, -5900, 127, 255, 0, 1500, 5), -- pipe light 2
            LIGHT(365, 7100, -6000, 255, 255, 255, 1000, 5), -- pipe light 3
        },
    },
}

gLightData.objectLights = {
    [id_bhvRedCoin]                   = 0xFF000032, -- red
    [id_bhvWingCap]                   = 0xFF000032, -- red
    [id_bhvRecoveryHeart]             = 0xFF000064, -- red
    [id_bhvFireParticleSpawner]       = 0xFF320064, -- orange
    [id_bhvFlame]                     = 0xFF320064, -- orange
    [id_bhvFlameBouncing]             = 0xFF320064, -- orange
    [id_bhvFlameFloatingLanding]      = 0xFF320064, -- orange
    [id_bhvFlameLargeBurningOut]      = 0xFF320064, -- orange
    [id_bhvFlameMovingForwardGrowing] = 0xFF320064, -- orange
    [id_bhvFlamethrowerFlame]         = 0xFF320064, -- orange
    [id_bhvBouncingFireballFlame]     = 0xFF320064, -- orange
    [id_bhvLllRotatingHexFlame]       = 0xFF320064, -- orange
    [id_bhvFlyguyFlame]               = 0xFF320064, -- orange
    [id_bhvVolcanoFlames]             = 0xFF320064, -- orange
    [id_bhvFlameBowser]               = 0xFF320064, -- orange
    [id_bhvSmallPiranhaFlame]         = 0xFF320064, -- orange
    [id_bhvExplosion]                 = 0xFF320064, -- orange
    [id_bhvToxBox]                    = 0xFF320064, -- orange
    [id_bhvBowserBombExplosion]       = 0xFF3200FA, -- orange
    [id_bhvCoinFormationSpawn]        = 0xFFFF1E5A, -- yellow
    [id_bhvYellowCoin]                = 0xFFFF1E32, -- yellow
    [id_bhvOneCoin]                   = 0xFFFF1E32, -- yellow
    [id_bhvSingleCoinGetsSpawned]     = 0xFFFF1E32, -- yellow
    [id_bhvThreeCoinsSpawn]           = 0xFFFF1E32, -- yellow
    [id_bhvTenCoinsSpawn]             = 0xFFFF1E32, -- yellow
    [id_bhvHomingAmp]                 = 0xFFFF1E32, -- yellow
    [id_bhvCirclingAmp]               = 0xFFFF1E32, -- yellow
    [id_bhvCelebrationStarSparkle]    = 0xFFFF1E5A, -- yellow
    [id_bhvStar]                      = 0xFFFF1E5A, -- yellow
    [id_bhvCelebrationStar]           = 0xFFFF1E5A, -- yellow
    [id_bhvSpawnedStar]               = 0xFFFF1E5A, -- yellow
    [id_bhvSpawnedStarNoLevelExit]    = 0xFFFF1E5A, -- yellow
    [id_bhvStarSpawnCoordinates]      = 0xFFFF1E5A, -- yellow
    [id_bhvKlepto]                    = 0xFFFF1EC8, -- yellow
    [id_bhvKoopaShell]                = 0x00FF0032, -- green
    [id_bhvMetalCap]                  = 0x00FF0032, -- green
    [id_bhvBlueCoinJumping]           = 0x7878FF64, -- light blue
    [id_bhvBlueCoinSliding]           = 0x7878FF64, -- light blue
    [id_bhvHiddenBlueCoin]            = 0x7878FF64, -- light blue
    [id_bhvMovingBlueCoin]            = 0x7878FF64, -- light blue
    [id_bhvMrIBlueCoin]               = 0x7878FF64, -- light blue
    [id_bhvBlueCoinSwitch]            = 0x5050FF64, -- blue
    [id_bhvVanishCap]                 = 0x0000FF32, -- deep blue
    [id_bhvBlueBowserFlame]           = 0x0000FF32, -- deep blue
    [id_bhvCapSwitch]                 = 0xFFFFFFA0, -- white
    [id_bhvCannon]                    = 0xFFFFFF32, -- white
    [id_bhvCastleFlagWaving]          = 0xFFFFFF5A, -- white
    [id_bhvExclamationBox]            = 0xFFFFFF5A, -- white
    [id_bhvWaterBombCannon]           = 0xFFFFFF5A, -- white
    [id_bhvBowserBomb]                = 0xFFFFFF5A, -- white
    [id_bhvWarpPipe]                  = 0xFFFFFF5A, -- white
    [id_bhvWaterLevelDiamond]         = 0xFFFFFF5A, -- white
    [id_bhvHiddenStarTrigger]         = 0xFFFFFF5A, -- white
}

--- @return Light[]|nil
--- Gets the map light spawn info for an area if it exists
function get_map_light_spawn_info()
    if not level_is_vanilla_level(gNetworkPlayers[0].currLevelNum) then return nil end

    local spawnInfo = gLightData.mapLights[gNetworkPlayers[0].currLevelNum]
    if spawnInfo == nil then return nil end

    local area = spawnInfo[gNetworkPlayers[0].currAreaIndex]
    if area == nil then return nil end
    return area
end

--- @param o Object
--- @return integer|nil
--- Gets the behavior parameters for an object light if they exist
function get_object_light_params(o)
    local bhv = get_id_from_behavior(o.behavior)
    return gLightData.objectLights[bhv]
end

-- for live reload
local lights = get_map_light_spawn_info()
if lights ~= nil then
    for i = 0, #lights - 1 do
        local light = lights[i + 1]
        le_set_light_pos(i, light.x, light.y, light.z)
        le_set_light_color(i, light.r, light.g, light.b)
        le_set_light_radius(i, light.radius)
        le_set_light_intensity(i, light.intensity)
    end
end

return gLightData