-- version
NM_VERSION_MAJOR = 1
NM_VERSION_MINOR = 0
NM_VERSION_PATCH = 0
NM_VERSION = math.tointeger(string.format("%d%d%d", NM_VERSION_MAJOR, NM_VERSION_MINOR, NM_VERSION_PATCH))

E_MODEL_NM_TTC_VOID   = smlua_model_util_get_id("nm_ttc_void_geo")
E_MODEL_NM_BBH_VOID   = smlua_model_util_get_id("nm_bbh_void_geo")
E_MODEL_NM_APPARITION = smlua_model_util_get_id("nm_apparition_geo")

STREAM_PIANO = audio_stream_load("piano.ogg")

SAMPLE_FLASHLIGHT = audio_sample_load("flashlight.ogg")
SAMPLE_JUMPSCARE  = audio_sample_load("jumpscare.ogg")

SEQ_LEVEL_FREEZING = SEQ_COUNT

COLOR_NIGHT = { r = 60,  g = 60,  b = 120 }
COLOR_BLUE  = { r = 150, g = 200, b = 255 }
COLOR_RED   = { r = 255, g = 0,   b = 0   }