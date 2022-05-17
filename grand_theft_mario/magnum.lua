E_MODEL_MAGNUM = smlua_model_util_get_id("magnum_geo")
E_VMODEL_MAGNUM = smlua_model_util_get_id("vmodel_magnum_geo")

GUN_MAGNUM = 1

gunTable[GUN_MAGNUM] = {
    model = E_MODEL_MAGNUM,
    vmodel = E_VMODEL_MAGNUM,
    arm = E_MODEL_ARM,
    metalArm = E_MODEL_ARM_METAL,
    gordonArm = E_MODEL_GORDON_ARM,
    dmg = 5,
    maxAmmo = 12,
    reloadTime = 85,
    shootTime = 24,
    shootSound = audio_sample_load("magnum_shoot.mp3"),
    reloadSound = audio_sample_load("magnum_reload.mp3"),
    bullet = E_MODEL_METALLIC_BALL,
    bulletScale = 0.2
}