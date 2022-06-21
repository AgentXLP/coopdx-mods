E_MODEL_MAGNUM = smlua_model_util_get_id("magnum_geo")
E_VMODEL_MAGNUM = smlua_model_util_get_id("vmodel_magnum_geo")

WEAPON_MAGNUM = 1

weaponTable[WEAPON_MAGNUM] = {
    name = "Magnum",
    gun = true,
    call = common_shoot,
    init = nil,
    loop = nil,
    model = E_MODEL_MAGNUM,
    arm = "arm",
    vmodel = "magnum",
    dmg = 5,
    maxAmmo = 12,
    reloadTime = 85,
    shootTime = 24,
    shootSound = audio_sample_load("magnum_shoot.mp3"),
    reloadSound = audio_sample_load("magnum_reload.mp3"),
    bullet = E_MODEL_METALLIC_BALL,
    bulletScale = 0.2
}
weaponCount = weaponCount + 1