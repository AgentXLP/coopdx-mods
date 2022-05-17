E_MODEL_PISTOL = smlua_model_util_get_id("pistol_geo")
E_VMODEL_PISTOL = smlua_model_util_get_id("vmodel_pistol_geo")

GUN_PISTOL = 0

gunTable[GUN_PISTOL] = {
    model = E_MODEL_PISTOL,
    vmodel = E_VMODEL_PISTOL,
    arm = E_MODEL_ARM,
    metalArm = E_MODEL_ARM_METAL,
    gordonArm = E_MODEL_GORDON_ARM,
    dmg = 3,
    maxAmmo = 18,
    reloadTime = 60,
    shootTime = 6,
    shootSound = audio_sample_load("pistol_shoot.mp3"),
    reloadSound = audio_sample_load("pistol_reload.mp3"),
    bullet = E_MODEL_YELLOW_COIN,
    bulletScale = 0.2
}