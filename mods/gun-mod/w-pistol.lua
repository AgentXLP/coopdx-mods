E_MODEL_PISTOL = smlua_model_util_get_id("pistol_geo")
E_VMODEL_PISTOL = smlua_model_util_get_id("vmodel_pistol_geo")

WEAPON_PISTOL = 0

weaponTable[WEAPON_PISTOL] = {
    name = "Pistol",
    gun = true,
    call = common_shoot,
    init = nil,
    loop = nil,
    model = E_MODEL_PISTOL,
    arm = "arm",
    vmodel = "pistol",
    dmg = 3,
    maxAmmo = 18,
    reloadTime = 60,
    shootTime = 6,
    shootSound = audio_sample_load("pistol_shoot.mp3"),
    reloadSound = audio_sample_load("pistol_reload.mp3"),
    bullet = E_MODEL_YELLOW_COIN,
    bulletScale = 0.2
}
weaponCount = weaponCount + 1