--- This is for the VSCode Lua plugin.

--- @diagnostic disable: missing-return

--- @param filename string
--- @return ModAudio
--- Loads an audio sample by `filename` (with extension)
function audio_sample_load(filename) end
--- @param filename string
--- @return ModAudio
--- Loads an audio stream by `filename` (with extension)
function audio_stream_load(filename) end
audio_sample_play = audio_play
audio_stream_play = audio_play
audio_sample_destroy = audio_destroy
audio_stream_destroy = audio_destroy
audio_sample_stop = audio_stop
audio_stream_stop = audio_stop
audio_stream_pause = audio_pause
audio_stream_get_position = audio_get_position
audio_stream_set_position = audio_set_position
audio_stream_get_looping = audio_get_looping
audio_stream_set_looping = audio_set_looping
audio_stream_set_loop_points = audio_set_loop_points
audio_stream_get_frequency = audio_get_frequency
audio_stream_set_frequency = audio_set_frequency
audio_stream_get_volume = audio_get_volume
audio_stream_set_volume = audio_set_volume
audio_stream_get_volume_channel = audio_get_volume_channel
audio_stream_set_volume_channel = audio_set_volume_channel

--- @type BehaviorId
bhvDNCSkybox = 0

--- @type BehaviorId
bhvDNCNoSkybox = 0

--- @type BehaviorId
bhvWCLightning = 0

--- @type BehaviorId
bhvWCRainDroplet = 0

--- @type BehaviorId
bhvWCSkybox = 0

--- @type BehaviorId
bhvWCAurora = 0

--- @type BehaviorId
bhvWPet = 0

--- @type BehaviorId
bhvNMFlashlight = 0

--- @type BehaviorId
bhvNMObjectLight = 0

--- @type BehaviorId
bhvNMBowserLight = 0

--- @type BehaviorId
bhvNMApparition = 0

--- @type BehaviorId
bhvUWFog = 0

--- @type BehaviorId
bhvUWObjectLight = 0

--- @type BehaviorId
bhvUWLevelCutscene = 0

--- @type BehaviorId
bhvUWDialogPrompt = 0

--- @type BehaviorId
bhvUWPlaque = 0

--- @type BehaviorId
bhvUWCutsceneStar = 0

--- @type BehaviorId
bhvUWLightTower = 0

--- @type BehaviorId
bhvUWLightTowerStar = 0

--- @type BehaviorId
bhvUWRegionLight = 0

--- @type BehaviorId
bhvUWSpring = 0

--- @type BehaviorId
bhvUWSpringChild = 0

--- @type BehaviorId
bhvUWBargainer = 0

--- @type BehaviorId
bhvUWLightOrb = 0

--- @type BehaviorId
bhvUWRisingCastle = 0

--- @type BehaviorId
bhvUWCastleWater = 0

--- @type BehaviorId
bhvUWNoiseStorm = 0

--- @type BehaviorId
bhvUWOldMan = 0

--- @type BehaviorId
bhvUWRegionSpawnpoint = 0

--- @type BehaviorId
bhvUWHUDPrompt = 0

--- @type BehaviorId
bhvUWFlameParticle = 0

--- @type BehaviorId
bhvUWSun = 0

--- @type BehaviorId
bhvUWArrow = 0

--- @type BehaviorId
bhvUWLightning = 0

--- @type BehaviorId
bhvUWTower = 0

--- @type BehaviorId
bhvUWFlyingDorrie = 0

--- @type BehaviorId
bhvUWZombie = 0

--- @type BehaviorId
bhvUWSwingingLight = 0

--- @type BehaviorId
bhvUWNoiseMesh = 0

--- @type BehaviorId
bhvUWApparition = 0

--- @type BehaviorId
bhvUWLaser = 0

--- @type BehaviorId
bhvUWBlueCoin = 0

--- @type BehaviorId
bhvUWEnemyFlag = 0

--- @type BehaviorId
bhvUWPyramid = 0

--- @type BehaviorId
bhvUWNoiseOrb = 0

--- @type BehaviorId
bhvUWTeleportPad = 0

--- @type BehaviorId
bhvUWCapSwitchBase = 0

--- @type BehaviorId
bhvUWCapSwitch = 0

--- @type BehaviorId
bhvUWCutsceneShockwave = 0

--- @type BehaviorId
bhvUWNoiseAttack = 0

--- @type BehaviorId
bhvUWShockwave = 0

--- @type BehaviorId
bhvUWStaticCollisionObject = 0

--- @type BehaviorId
bhvUWStaticCollisionObject2 = 0

--- @type BehaviorId
bhvUWBossArena = 0

--- @type BehaviorId
bhvUWBossArenaGodrays = 0

--- @type BehaviorId
bhvUWCrashingCastle = 0

--- @type BehaviorId
bhvUWLightningSpawner = 0

--- @type BehaviorId
bhvUWEnemyFlagManager = 0

--- @type BehaviorId
bhvUWMerchant = 0

--- @type BehaviorId
bhvUWRainDroplet = 0


--- @type BehaviorId
bhvNDFlood = 0

--- @type BehaviorId
bhvNDSkybox = 0

--- @type BehaviorId
bhvNDRainDroplet = 0

--- @type BehaviorId
bhvNDAcidRain = 0

--- @type BehaviorId
bhvNDTornado = 0

--- @type BehaviorId
bhvNDHeat = 0

--- @type BehaviorId
bhvNDCold = 0

--- @type BehaviorId
bhvNDFog = 0

--- @type BehaviorId
bhvNDMiasma = 0

--- @type BehaviorId
bhvNDMeteorShower = 0

--- @type BehaviorId
bhvNDMeteor = 0

--- @type BehaviorId
bhvNDShockwave = 0

--- @type BehaviorId
bhvNDCorpse = 0

--- @type BehaviorId
bhvNDThunderstorm = 0

--- @type BehaviorId
bhvNDLightning = 0