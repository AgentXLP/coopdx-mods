-- models
E_MODEL_BULLET_HOLE = smlua_model_util_get_id("bullet_hole_geo")
E_MODEL_SINGLE_ARM = smlua_model_util_get_id("arm_geo")
E_MODEL_PISTOL = smlua_model_util_get_id("pistol_geo")
E_MODEL_MAGNUM = smlua_model_util_get_id("magnum_geo")
E_MODEL_AK47 = smlua_model_util_get_id("ak47_geo")
E_MODEL_SHOTGUN = smlua_model_util_get_id("shotgun_geo")
E_MODEL_ARROW = smlua_model_util_get_id("arrow_geo")
E_MODEL_TROLL_EXPLOSION = smlua_model_util_get_id("troll_explosion_geo")

-- textures
TEX_CROSSHAIR = get_texture_info("gun_mod_crosshair")

-- custom sounds
SOUND_CUSTOM_IMPACT = audio_sample_load("impact.mp3")
SOUND_CUSTOM_RICOCHET = audio_sample_load("ricochet.mp3")
SOUND_CUSTOM_DRY = audio_sample_load("dry.mp3")
SOUND_CUSTOM_BAD_TO_THE_BONE = audio_sample_load("bad_to_the_bone_riff.mp3")

-- actions
-- ACT_CUSTOM_MOVEMENT = allocate_mario_action(ACT_GROUP_CUTSCENE)

-- packet ids
PACKET_ATTACK = 0
PACKET_SOUND = 1

-- misc
START_IN_FIRST_PERSON = true

MAX_INVENTORY_SLOTS = 2

HEALTH_SIGN = 30
HEALTH_BREAKABLE_BOX = 30
HEALTH_BOWLING_BALL = 75
HEALTH_CHUCKYA = 60
HEALTH_KING_BOBOMB = 200
HEALTH_BOWSER = 300