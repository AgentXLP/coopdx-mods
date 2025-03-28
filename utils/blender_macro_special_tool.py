import bpy
import os

from mathutils import Euler
import math

LEVEL = "bob"

macro_yellow_coin = "macro_yellow_coin"
macro_yellow_coin_2 = "macro_yellow_coin_2"        
macro_moving_blue_coin = "macro_moving_blue_coin"  
macro_sliding_blue_coin = "macro_sliding_blue_coin"
macro_red_coin = "macro_red_coin"
macro_empty_5 = "macro_empty_5"
macro_coin_line_horizontal = "macro_coin_line_horizontal"
macro_coin_ring_horizontal = "macro_coin_ring_horizontal"
macro_coin_arrow = "macro_coin_arrow"
macro_coin_line_horizontal_flying = "macro_coin_line_horizontal_flying"
macro_coin_line_vertical = "macro_coin_line_vertical"
macro_coin_ring_horizontal_flying = "macro_coin_ring_horizontal_flying"
macro_coin_ring_vertical = "macro_coin_ring_vertical"
macro_coin_arrow_flying = "macro_coin_arrow_flying"
macro_hidden_star_trigger = "macro_hidden_star_trigger"
macro_empty_15 = "macro_empty_15"
macro_empty_16 = "macro_empty_16"
macro_empty_17 = "macro_empty_17"
macro_empty_18 = "macro_empty_18"
macro_empty_19 = "macro_empty_19"
macro_fake_star = "macro_fake_star"
macro_wooden_signpost = "macro_wooden_signpost"
macro_cannon_closed = "macro_cannon_closed"
macro_bobomb_buddy_opens_cannon = "macro_bobomb_buddy_opens_cannon"
macro_butterfly = "macro_butterfly"
macro_bouncing_fireball_copy = "macro_bouncing_fireball_copy"
macro_fish_group_3 = "macro_fish_group_3"
macro_fish_group = "macro_fish_group"
macro_unknown_28 = "macro_unknown_28"
macro_hidden_1up_in_pole = "macro_hidden_1up_in_pole"
macro_huge_goomba = "macro_huge_goomba"
macro_tiny_goomba = "macro_tiny_goomba"
macro_goomba_triplet_spawner = "macro_goomba_triplet_spawner"
macro_goomba_quintuplet_spawner = "macro_goomba_quintuplet_spawner"
macro_sign_on_wall = "macro_sign_on_wall"
macro_chuckya = "macro_chuckya"
macro_cannon_open = "macro_cannon_open"
macro_goomba = "macro_goomba"
macro_homing_amp = "macro_homing_amp"
macro_circling_amp = "macro_circling_amp"
macro_unknown_40 = "macro_unknown_40"
macro_unknown_41 = "macro_unknown_41"
macro_free_bowling_ball = "macro_free_bowling_ball"
macro_snufit = "macro_snufit"
macro_recovery_heart = "macro_recovery_heart"
macro_1up_sliding = "macro_1up_sliding"
macro_1up = "macro_1up"
macro_1up_jump_on_approach = "macro_1up_jump_on_approach"
macro_hidden_1up = "macro_hidden_1up"
macro_hidden_1up_trigger = "macro_hidden_1up_trigger"
macro_1up_2 = "macro_1up_2"
macro_1up_3 = "macro_1up_3"
macro_empty_52 = "macro_empty_52"
macro_blue_coin_switch = "macro_blue_coin_switch"
macro_hidden_blue_coin = "macro_hidden_blue_coin"
macro_wing_cap_switch = "macro_wing_cap_switch"
macro_metal_cap_switch = "macro_metal_cap_switch"
macro_vanish_cap_switch = "macro_vanish_cap_switch"
macro_yellow_cap_switch = "macro_yellow_cap_switch"
macro_unknown_59 = "macro_unknown_59"
macro_box_wing_cap = "macro_box_wing_cap"
macro_box_metal_cap = "macro_box_metal_cap"
macro_box_vanish_cap = "macro_box_vanish_cap"
macro_box_koopa_shell = "macro_box_koopa_shell"
macro_box_one_coin = "macro_box_one_coin"
macro_box_three_coins = "macro_box_three_coins"
macro_box_ten_coins = "macro_box_ten_coins"
macro_box_1up = "macro_box_1up"
macro_box_star_1 = "macro_box_star_1"
macro_breakable_box_no_coins = "macro_breakable_box_no_coins"
macro_breakable_box_three_coins = "macro_breakable_box_three_coins"
macro_pushable_metal_box = "macro_pushable_metal_box"
macro_breakable_box_small = "macro_breakable_box_small"
macro_floor_switch_hidden_objects = "macro_floor_switch_hidden_objects"
macro_hidden_box = "macro_hidden_box"
macro_hidden_object_2 = "macro_hidden_object_2"
macro_hidden_object_3 = "macro_hidden_object_3"
macro_breakable_box_giant = "macro_breakable_box_giant"
macro_koopa_shell_underwater = "macro_koopa_shell_underwater"
macro_box_1up_running_away = "macro_box_1up_running_away"
macro_empty_80 = "macro_empty_80"
macro_bullet_bill_cannon = "macro_bullet_bill_cannon"
macro_heave_ho = "macro_heave_ho"
macro_empty_83 = "macro_empty_83"
macro_thwomp = "macro_thwomp"
macro_fire_spitter = "macro_fire_spitter"
macro_fire_fly_guy = "macro_fire_fly_guy"
macro_jumping_box = "macro_jumping_box"
macro_butterfly_triplet = "macro_butterfly_triplet"
macro_butterfly_triplet_2 = "macro_butterfly_triplet_2"
macro_empty_90 = "macro_empty_90"
macro_empty_91 = "macro_empty_91"
macro_empty_92 = "macro_empty_92"
macro_bully = "macro_bully"
macro_bully_2 = "macro_bully_2"
macro_empty_95 = "macro_empty_95"
macro_unknown_96 = "macro_unknown_96"
macro_bouncing_fireball = "macro_bouncing_fireball"
macro_flamethrower = "macro_flamethrower"
macro_empty_99 = "macro_empty_99"
macro_empty_100 = "macro_empty_100"
macro_empty_101 = "macro_empty_101"
macro_empty_102 = "macro_empty_102"
macro_empty_103 = "macro_empty_103"
macro_empty_104 = "macro_empty_104"
macro_empty_105 = "macro_empty_105"
macro_wooden_post = "macro_wooden_post"
macro_water_bomb_spawner = "macro_water_bomb_spawner"
macro_enemy_lakitu = "macro_enemy_lakitu"
macro_bob_koopa_the_quick = "macro_bob_koopa_the_quick"
macro_koopa_race_endpoint = "macro_koopa_race_endpoint"
macro_bobomb = "macro_bobomb"
macro_water_bomb_cannon_copy = "macro_water_bomb_cannon_copy"
macro_bobomb_buddy_opens_cannon_copy = "macro_bobomb_buddy_opens_cannon_copy"
macro_water_bomb_cannon = "macro_water_bomb_cannon"
macro_bobomb_still = "macro_bobomb_still"
macro_empty_116 = "macro_empty_116"
macro_empty_117 = "macro_empty_117"
macro_empty_118 = "macro_empty_118"
macro_empty_119 = "macro_empty_119"
macro_empty_120 = "macro_empty_120"
macro_empty_121 = "macro_empty_121"
macro_empty_122 = "macro_empty_122"
macro_unknown_123 = "macro_unknown_123"
macro_empty_124 = "macro_empty_124"
macro_unagi = "macro_unagi"
macro_sushi = "macro_sushi"
macro_empty_127 = "macro_empty_127"
macro_empty_128 = "macro_empty_128"
macro_empty_129 = "macro_empty_129"
macro_empty_130 = "macro_empty_130"
macro_empty_131 = "macro_empty_131"
macro_empty_132 = "macro_empty_132"
macro_empty_133 = "macro_empty_133"
macro_empty_134 = "macro_empty_134"
macro_empty_135 = "macro_empty_135"
macro_empty_136 = "macro_empty_136"
macro_unknown_137 = "macro_unknown_137"
macro_tornado = "macro_tornado"
macro_pokey = "macro_pokey"
macro_pokey_copy = "macro_pokey_copy"
macro_tox_box = "macro_tox_box"
macro_empty_142 = "macro_empty_142"
macro_empty_143 = "macro_empty_143"
macro_empty_144 = "macro_empty_144"
macro_empty_145 = "macro_empty_145"
macro_empty_146 = "macro_empty_146"
macro_empty_147 = "macro_empty_147"
macro_empty_148 = "macro_empty_148"
macro_empty_149 = "macro_empty_149"
macro_empty_150 = "macro_empty_150"
macro_monty_mole_2 = "macro_monty_mole_2"
macro_monty_mole = "macro_monty_mole"
macro_monty_mole_hole = "macro_monty_mole_hole"
macro_fly_guy = "macro_fly_guy"
macro_empty_155 = "macro_empty_155"
macro_wiggler = "macro_wiggler"
macro_empty_157 = "macro_empty_157"
macro_empty_158 = "macro_empty_158"
macro_empty_159 = "macro_empty_159"
macro_empty_160 = "macro_empty_160"
macro_empty_161 = "macro_empty_161"
macro_empty_162 = "macro_empty_162"
macro_empty_163 = "macro_empty_163"
macro_empty_164 = "macro_empty_164"
macro_spindrift = "macro_spindrift"
macro_mr_blizzard = "macro_mr_blizzard"
macro_mr_blizzard_copy = "macro_mr_blizzard_copy"
macro_empty_168 = "macro_empty_168"
macro_small_penguin = "macro_small_penguin"
macro_tuxies_mother = "macro_tuxies_mother"
macro_tuxies_mother_copy = "macro_tuxies_mother_copy"
macro_mr_blizzard_2 = "macro_mr_blizzard_2"
macro_empty_173 = "macro_empty_173"
macro_empty_174 = "macro_empty_174"
macro_empty_175 = "macro_empty_175"
macro_empty_176 = "macro_empty_176"
macro_empty_177 = "macro_empty_177"
macro_empty_178 = "macro_empty_178"
macro_empty_179 = "macro_empty_179"
macro_empty_180 = "macro_empty_180"
macro_empty_181 = "macro_empty_181"
macro_empty_182 = "macro_empty_182"
macro_empty_183 = "macro_empty_183"
macro_empty_184 = "macro_empty_184"
macro_empty_185 = "macro_empty_185"
macro_empty_186 = "macro_empty_186"
macro_empty_187 = "macro_empty_187"
macro_empty_188 = "macro_empty_188"
macro_haunted_chair_copy = "macro_haunted_chair_copy"
macro_haunted_chair = "macro_haunted_chair"
macro_haunted_chair_copy2 = "macro_haunted_chair_copy2"
macro_boo = "macro_boo"
macro_boo_copy = "macro_boo_copy"
macro_boo_group = "macro_boo_group"
macro_boo_with_cage = "macro_boo_with_cage"
macro_beta_key = "macro_beta_key"
macro_empty_197 = "macro_empty_197"
macro_empty_198 = "macro_empty_198"
macro_empty_199 = "macro_empty_199"
macro_empty_200 = "macro_empty_200"
macro_empty_201 = "macro_empty_201"
macro_empty_202 = "macro_empty_202"
macro_empty_203 = "macro_empty_203"
macro_empty_204 = "macro_empty_204"
macro_empty_205 = "macro_empty_205"
macro_empty_206 = "macro_empty_206"
macro_empty_207 = "macro_empty_207"
macro_empty_208 = "macro_empty_208"
macro_empty_209 = "macro_empty_209"
macro_empty_210 = "macro_empty_210"
macro_empty_211 = "macro_empty_211"
macro_empty_212 = "macro_empty_212"
macro_empty_213 = "macro_empty_213"
macro_empty_214 = "macro_empty_214"
macro_empty_215 = "macro_empty_215"
macro_empty_216 = "macro_empty_216"
macro_empty_217 = "macro_empty_217"
macro_empty_218 = "macro_empty_218"
macro_empty_219 = "macro_empty_219"
macro_empty_220 = "macro_empty_220"
macro_empty_221 = "macro_empty_221"
macro_empty_222 = "macro_empty_222"
macro_empty_223 = "macro_empty_223"
macro_empty_224 = "macro_empty_224"
macro_empty_225 = "macro_empty_225"
macro_empty_226 = "macro_empty_226"
macro_empty_227 = "macro_empty_227"
macro_empty_228 = "macro_empty_228"
macro_empty_229 = "macro_empty_229"
macro_empty_230 = "macro_empty_230"
macro_empty_231 = "macro_empty_231"
macro_empty_232 = "macro_empty_232"
macro_empty_233 = "macro_empty_233"
macro_chirp_chirp = "macro_chirp_chirp"
macro_seaweed_bundle = "macro_seaweed_bundle"
macro_beta_chest = "macro_beta_chest"
macro_water_mine = "macro_water_mine"
macro_fish_group_4 = "macro_fish_group_4"
macro_fish_group_2 = "macro_fish_group_2"
macro_jet_stream_ring_spawner = "macro_jet_stream_ring_spawner"
macro_jet_stream_ring_spawner_copy = "macro_jet_stream_ring_spawner_copy"
macro_skeeter = "macro_skeeter"
macro_clam_shell = "macro_clam_shell"
macro_empty_244 = "macro_empty_244"
macro_empty_245 = "macro_empty_245"
macro_empty_246 = "macro_empty_246"
macro_empty_247 = "macro_empty_247"
macro_empty_248 = "macro_empty_248"
macro_empty_249 = "macro_empty_249"
macro_empty_250 = "macro_empty_250"
macro_ukiki = "macro_ukiki"
macro_ukiki_2 = "macro_ukiki_2"
macro_piranha_plant = "macro_piranha_plant"
macro_empty_254 = "macro_empty_254"
macro_whomp = "macro_whomp"
macro_chain_chomp = "macro_chain_chomp"
macro_empty_257 = "macro_empty_257"
macro_koopa = "macro_koopa"
macro_koopa_shellless = "macro_koopa_shellless"
macro_wooden_post_copy = "macro_wooden_post_copy"
macro_fire_piranha_plant = "macro_fire_piranha_plant"
macro_fire_piranha_plant_2 = "macro_fire_piranha_plant_2"
macro_thi_koopa_the_quick = "macro_thi_koopa_the_quick"
macro_empty_264 = "macro_empty_264"
macro_empty_265 = "macro_empty_265"
macro_empty_266 = "macro_empty_266"
macro_empty_267 = "macro_empty_267"
macro_empty_268 = "macro_empty_268"
macro_empty_269 = "macro_empty_269"
macro_empty_270 = "macro_empty_270"
macro_empty_271 = "macro_empty_271"
macro_empty_272 = "macro_empty_272"
macro_empty_273 = "macro_empty_273"
macro_empty_274 = "macro_empty_274"
macro_empty_275 = "macro_empty_275"
macro_empty_276 = "macro_empty_276"
macro_empty_277 = "macro_empty_277"
macro_empty_278 = "macro_empty_278"
macro_empty_279 = "macro_empty_279"
macro_empty_280 = "macro_empty_280"
macro_moneybag = "macro_moneybag"
macro_empty_282 = "macro_empty_282"
macro_empty_283 = "macro_empty_283"
macro_empty_284 = "macro_empty_284"
macro_empty_285 = "macro_empty_285"
macro_empty_286 = "macro_empty_286"
macro_empty_287 = "macro_empty_287"
macro_empty_288 = "macro_empty_288"
macro_swoop = "macro_swoop"
macro_swoop_2 = "macro_swoop_2"
macro_mr_i = "macro_mr_i"
macro_scuttlebug_spawner = "macro_scuttlebug_spawner"
macro_scuttlebug = "macro_scuttlebug"
macro_empty_294 = "macro_empty_294"
macro_empty_295 = "macro_empty_295"
macro_empty_296 = "macro_empty_296"
macro_empty_297 = "macro_empty_297"
macro_empty_298 = "macro_empty_298"
macro_empty_299 = "macro_empty_299"
macro_empty_300 = "macro_empty_300"
macro_empty_301 = "macro_empty_301"
macro_empty_302 = "macro_empty_302"
macro_unknown_303 = "macro_unknown_303"
macro_empty_304 = "macro_empty_304"
macro_empty_305 = "macro_empty_305"
macro_empty_306 = "macro_empty_306"
macro_empty_307 = "macro_empty_307"
macro_empty_308 = "macro_empty_308"
macro_empty_309 = "macro_empty_309"
macro_empty_310 = "macro_empty_310"
macro_empty_311 = "macro_empty_311"
macro_empty_312 = "macro_empty_312"
macro_ttc_rotating_cube = "macro_ttc_rotating_cube"
macro_ttc_rotating_prism = "macro_ttc_rotating_prism"
macro_ttc_pendulum = "macro_ttc_pendulum"
macro_ttc_large_treadmill = "macro_ttc_large_treadmill"
macro_ttc_small_treadmill = "macro_ttc_small_treadmill"
macro_ttc_push_block = "macro_ttc_push_block"
macro_ttc_rotating_hexagon = "macro_ttc_rotating_hexagon"
macro_ttc_rotating_triangle = "macro_ttc_rotating_triangle"
macro_ttc_pit_block = "macro_ttc_pit_block"
macro_ttc_pit_block_2 = "macro_ttc_pit_block_2"
macro_ttc_elevator_platform = "macro_ttc_elevator_platform"
macro_ttc_clock_hand = "macro_ttc_clock_hand"
macro_ttc_spinner = "macro_ttc_spinner"
macro_ttc_small_gear = "macro_ttc_small_gear"
macro_ttc_large_gear = "macro_ttc_large_gear"
macro_ttc_large_treadmill_2 = "macro_ttc_large_treadmill_2"
macro_ttc_small_treadmill_2 = "macro_ttc_small_treadmill_2"
macro_empty_330 = "macro_empty_330"
macro_empty_331 = "macro_empty_331"
macro_empty_332 = "macro_empty_332"
macro_empty_333 = "macro_empty_333"
macro_empty_334 = "macro_empty_334"
macro_empty_335 = "macro_empty_335"
macro_empty_336 = "macro_empty_336"
macro_empty_337 = "macro_empty_337"
macro_empty_338 = "macro_empty_338"
macro_box_star_2 = "macro_box_star_2"
macro_box_star_3 = "macro_box_star_3"
macro_box_star_4 = "macro_box_star_4"
macro_box_star_5 = "macro_box_star_5"
macro_box_star_6 = "macro_box_star_6"
macro_empty_344 = "macro_empty_344"
macro_empty_345 = "macro_empty_345"
macro_empty_346 = "macro_empty_346"
macro_empty_347 = "macro_empty_347"
macro_empty_348 = "macro_empty_348"
macro_empty_349 = "macro_empty_349"
macro_bits_sliding_platform = "macro_bits_sliding_platform"
macro_bits_twin_sliding_platforms = "macro_bits_twin_sliding_platforms"
macro_bits_unknown_352 = "macro_bits_unknown_352"
macro_bits_octagonal_platform = "macro_bits_octagonal_platform"
macro_bits_staircase = "macro_bits_staircase"
macro_empty_355 = "macro_empty_355"
macro_empty_356 = "macro_empty_356"
macro_bits_ferris_wheel_axle = "macro_bits_ferris_wheel_axle"
macro_bits_arrow_platform = "macro_bits_arrow_platform"
macro_bits_seesaw_platform = "macro_bits_seesaw_platform"
macro_bits_tilting_w_platform = "macro_bits_tilting_w_platform"
macro_empty_361 = "macro_empty_361"
macro_empty_362 = "macro_empty_362"
macro_empty_363 = "macro_empty_363"
macro_empty_364 = "macro_empty_364"
macro_empty_36 = "macro_empty_36"

special_bubble_tree = "special_bubble_tree"

DIALOG_000 = "DIALOG_000"
DIALOG_001 = "DIALOG_001"
DIALOG_002 = "DIALOG_002"
DIALOG_003 = "DIALOG_003"
DIALOG_004 = "DIALOG_004"
DIALOG_005 = "DIALOG_005"
DIALOG_006 = "DIALOG_006"
DIALOG_007 = "DIALOG_007"
DIALOG_008 = "DIALOG_008"
DIALOG_009 = "DIALOG_009"
DIALOG_010 = "DIALOG_010"
DIALOG_011 = "DIALOG_011"
DIALOG_012 = "DIALOG_012"
DIALOG_013 = "DIALOG_013"
DIALOG_014 = "DIALOG_014"
DIALOG_015 = "DIALOG_015"
DIALOG_016 = "DIALOG_016"
DIALOG_017 = "DIALOG_017"
DIALOG_018 = "DIALOG_018"
DIALOG_019 = "DIALOG_019"
DIALOG_020 = "DIALOG_020"
DIALOG_021 = "DIALOG_021"
DIALOG_022 = "DIALOG_022"
DIALOG_023 = "DIALOG_023"
DIALOG_024 = "DIALOG_024"
DIALOG_025 = "DIALOG_025"
DIALOG_026 = "DIALOG_026"
DIALOG_027 = "DIALOG_027"
DIALOG_028 = "DIALOG_028"
DIALOG_029 = "DIALOG_029"
DIALOG_030 = "DIALOG_030"
DIALOG_031 = "DIALOG_031"
DIALOG_032 = "DIALOG_032"
DIALOG_033 = "DIALOG_033"
DIALOG_034 = "DIALOG_034"
DIALOG_035 = "DIALOG_035"
DIALOG_036 = "DIALOG_036"
DIALOG_037 = "DIALOG_037"
DIALOG_038 = "DIALOG_038"
DIALOG_039 = "DIALOG_039"
DIALOG_040 = "DIALOG_040"
DIALOG_041 = "DIALOG_041"
DIALOG_042 = "DIALOG_042"
DIALOG_043 = "DIALOG_043"
DIALOG_044 = "DIALOG_044"
DIALOG_045 = "DIALOG_045"
DIALOG_046 = "DIALOG_046"
DIALOG_047 = "DIALOG_047"
DIALOG_048 = "DIALOG_048"
DIALOG_049 = "DIALOG_049"
DIALOG_050 = "DIALOG_050"
DIALOG_051 = "DIALOG_051"
DIALOG_052 = "DIALOG_052"
DIALOG_053 = "DIALOG_053"
DIALOG_054 = "DIALOG_054"
DIALOG_055 = "DIALOG_055"
DIALOG_056 = "DIALOG_056"
DIALOG_057 = "DIALOG_057"
DIALOG_058 = "DIALOG_058"
DIALOG_059 = "DIALOG_059"
DIALOG_060 = "DIALOG_060"
DIALOG_061 = "DIALOG_061"
DIALOG_062 = "DIALOG_062"
DIALOG_063 = "DIALOG_063"
DIALOG_064 = "DIALOG_064"
DIALOG_065 = "DIALOG_065"
DIALOG_066 = "DIALOG_066"
DIALOG_067 = "DIALOG_067"
DIALOG_068 = "DIALOG_068"
DIALOG_069 = "DIALOG_069"
DIALOG_070 = "DIALOG_070"
DIALOG_071 = "DIALOG_071"
DIALOG_072 = "DIALOG_072"
DIALOG_073 = "DIALOG_073"
DIALOG_074 = "DIALOG_074"
DIALOG_075 = "DIALOG_075"
DIALOG_076 = "DIALOG_076"
DIALOG_077 = "DIALOG_077"
DIALOG_078 = "DIALOG_078"
DIALOG_079 = "DIALOG_079"
DIALOG_080 = "DIALOG_080"
DIALOG_081 = "DIALOG_081"
DIALOG_082 = "DIALOG_082"
DIALOG_083 = "DIALOG_083"
DIALOG_084 = "DIALOG_084"
DIALOG_085 = "DIALOG_085"
DIALOG_086 = "DIALOG_086"
DIALOG_087 = "DIALOG_087"
DIALOG_088 = "DIALOG_088"
DIALOG_089 = "DIALOG_089"
DIALOG_090 = "DIALOG_090"
DIALOG_091 = "DIALOG_091"
DIALOG_092 = "DIALOG_092"
DIALOG_093 = "DIALOG_093"
DIALOG_094 = "DIALOG_094"
DIALOG_095 = "DIALOG_095"
DIALOG_096 = "DIALOG_096"
DIALOG_097 = "DIALOG_097"
DIALOG_098 = "DIALOG_098"
DIALOG_099 = "DIALOG_099"
DIALOG_100 = "DIALOG_100"
DIALOG_101 = "DIALOG_101"
DIALOG_102 = "DIALOG_102"
DIALOG_103 = "DIALOG_103"
DIALOG_104 = "DIALOG_104"
DIALOG_105 = "DIALOG_105"
DIALOG_106 = "DIALOG_106"
DIALOG_107 = "DIALOG_107"
DIALOG_108 = "DIALOG_108"
DIALOG_109 = "DIALOG_109"
DIALOG_110 = "DIALOG_110"
DIALOG_111 = "DIALOG_111"
DIALOG_112 = "DIALOG_112"
DIALOG_113 = "DIALOG_113"
DIALOG_114 = "DIALOG_114"
DIALOG_115 = "DIALOG_115"
DIALOG_116 = "DIALOG_116"
DIALOG_117 = "DIALOG_117"
DIALOG_118 = "DIALOG_118"
DIALOG_119 = "DIALOG_119"
DIALOG_120 = "DIALOG_120"
DIALOG_121 = "DIALOG_121"
DIALOG_122 = "DIALOG_122"
DIALOG_123 = "DIALOG_123"
DIALOG_124 = "DIALOG_124"
DIALOG_125 = "DIALOG_125"
DIALOG_126 = "DIALOG_126"
DIALOG_127 = "DIALOG_127"
DIALOG_128 = "DIALOG_128"
DIALOG_129 = "DIALOG_129"
DIALOG_130 = "DIALOG_130"
DIALOG_131 = "DIALOG_131"
DIALOG_132 = "DIALOG_132"
DIALOG_133 = "DIALOG_133"
DIALOG_134 = "DIALOG_134"
DIALOG_135 = "DIALOG_135"
DIALOG_136 = "DIALOG_136"
DIALOG_137 = "DIALOG_137"
DIALOG_138 = "DIALOG_138"
DIALOG_139 = "DIALOG_139"
DIALOG_140 = "DIALOG_140"
DIALOG_141 = "DIALOG_141"
DIALOG_142 = "DIALOG_142"
DIALOG_143 = "DIALOG_143"
DIALOG_144 = "DIALOG_144"
DIALOG_145 = "DIALOG_145"
DIALOG_146 = "DIALOG_146"
DIALOG_147 = "DIALOG_147"
DIALOG_148 = "DIALOG_148"
DIALOG_149 = "DIALOG_149"
DIALOG_150 = "DIALOG_150"
DIALOG_151 = "DIALOG_151"
DIALOG_152 = "DIALOG_152"
DIALOG_153 = "DIALOG_153"
DIALOG_154 = "DIALOG_154"
DIALOG_155 = "DIALOG_155"
DIALOG_156 = "DIALOG_156"
DIALOG_157 = "DIALOG_157"
DIALOG_158 = "DIALOG_158"
DIALOG_159 = "DIALOG_159"
DIALOG_160 = "DIALOG_160"
DIALOG_161 = "DIALOG_161"
DIALOG_162 = "DIALOG_162"
DIALOG_163 = "DIALOG_163"
DIALOG_164 = "DIALOG_164"
DIALOG_165 = "DIALOG_165"
DIALOG_166 = "DIALOG_166"
DIALOG_167 = "DIALOG_167"
DIALOG_168 = "DIALOG_168"
DIALOG_169 = "DIALOG_169"

def format(num):
    if num % 1 == 0:
        return int(num)
    else:
        return num

def MACRO_OBJECT(preset, yaw, posX, posY, posZ, behParam = "0"):
    posX = format(posX / bpy.context.scene.blenderToSM64Scale)
    posY = format(posY / bpy.context.scene.blenderToSM64Scale)
    posZ = format(posZ / bpy.context.scene.blenderToSM64Scale)
    return [preset, yaw, posX, -posZ, posY, behParam]

def MACRO_OBJECT_WITH_BEH_PARAM(preset, yaw, posX, posY, posZ, behParam):
    return MACRO_OBJECT(preset, yaw, posX, posY, posZ, behParam)

def SPECIAL_OBJECT_WITH_YAW(preset, posX, posY, posZ, yaw):
    return MACRO_OBJECT(preset, yaw, posX, posY, posZ, 0)

def SPECIAL_OBJECT_WITH_YAW_AND_PARAM(preset, posX, posY, posZ, yaw, behParam):
    return MACRO_OBJECT(preset, yaw, posX, posY, posZ, behParam)

def SPECIAL_OBJECT(preset, posX, posY, posZ):
    return MACRO_OBJECT(preset, 0, posX, posY, posZ)

with open(os.path.join(bpy.context.scene.decompPath, f"levels/{LEVEL}/areas/1/macro.inc.c"), "r") as f:
    data = f.read().split("\n")
    for line in data:
        line = line.strip()
        if line.startswith("MACRO") and "END" not in line:
            line = line.replace("),", ")")
            line = line.replace("/*preset*/ ", "")
            line = line.replace(" /*yaw*/", "")
            line = line.replace(" /*pos*/", "")
            line = line.replace(" /*behParam*/", "")
            line = line.replace(" /*behParam2*/", "")

            macro = eval(line)

            obj = bpy.data.objects.new("Empty", None)
            bpy.context.scene.collection.objects.link(obj)
            obj.name = "Macro " + macro[0]
            obj.sm64_obj_type = "Macro"
            obj.sm64_macro_enum = "Custom"
            obj.sm64_obj_preset = macro[0]
            obj.location = [macro[2], macro[3], macro[4]]
            obj.rotation_euler.rotate(Euler((0, math.radians(macro[1]), 0)))
            if len(macro) > 5:
                obj.fast64.sm64.game_object.bparams = str(macro[5])
                obj.fast64.sm64.game_object.use_individual_params = False

'''               
with open(os.path.join(bpy.context.scene.decompPath, f"levels/{LEVEL}/areas/1/collision.inc.c"), "r") as f:
    data = f.read().split("\n")
    for line in data:
        line = line.strip()
        if line.startswith("SPECIAL_OBJECT"):
            line = line.replace("),", ")")
            line = line.replace("/*preset*/ ", "")
            line = line.replace(" /*pos*/", "")

            special = eval(line)

            obj = bpy.data.objects.new("Empty", None)
            bpy.context.scene.collection.objects.link(obj)
            obj.name = "Special " + special[0]
            obj.sm64_obj_type = "Special"
            obj.sm64_special_enum = "Custom"
            obj.sm64_obj_preset = special[0]
            obj.location = [special[2], special[3], special[4]]
            obj.rotation_euler.rotate(Euler((0, math.radians(special[1]), 0)))
            # if len(special) > 5:
            #     obj.fast64.sm64.game_object.bparams = str(special[5])
            #     obj.fast64.sm64.game_object.use_individual_params = False
'''