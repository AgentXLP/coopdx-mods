function on_dmg_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    gGlobalSyncTable.dmg = tonumber(msg)
    djui_chat_message_create("Gun damage set to " .. msg)
end

function on_infammo_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    if msg == "on" then
        gGlobalSyncTable.infAmmo = true
        djui_chat_message_create("Infinite ammo on")
    else
        gGlobalSyncTable.infAmmo = false
        djui_chat_message_create("Infinite ammo off")
    end
end

function on_maxammo_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    gGlobalSyncTable.maxAmmo = tonumber(msg)
    for i=0,(MAX_PLAYERS-1) do
        if gPlayerSyncTable[i].ammo > gGlobalSyncTable.maxAmmo then
            gPlayerSyncTable[i].ammo = gGlobalSyncTable.maxAmmo
        end
    end
    djui_chat_message_create("Max ammo set to " .. msg)
end

function on_reloadtime_command(msg)
    if gGlobalSyncTable.infAmmo == false then
        return
    end

    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    reloadTime = tonumber(msg)
    djui_chat_message_create("Reload time set to " .. msg)
end

function on_shoottime_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    shootTime = tonumber(msg)
    djui_chat_message_create("Shoot time set to " .. msg)
end

function on_warpammo_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    if msg == "on" then
        gGlobalSyncTable.warpAmmo = true
        djui_chat_message_create("Regenerate ammo on warp on")
    else
        gGlobalSyncTable.warpAmmo = false
        djui_chat_message_create("Regenerate ammo on warp off")
    end
end

function on_kill_command(msg)
    gMarioStates[0].health = 0xff
end

function on_refill_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return
    end

    gPlayerSyncTable[0].ammo = gGlobalSyncTable.maxAmmo
end

hook_chat_command("dmg", "to modify the damage bullets have", on_dmg_command)
hook_chat_command("infammo", "[on|off] turn infinite ammo on or off", on_infammo_command)
hook_chat_command("maxammo", "to modify the max ammo amount before needing to reload", on_maxammo_command)
hook_chat_command("reloadtime", "to modify the cooldown while reloading, doesn't work if infinite ammo is off", on_reloadtime_command)
hook_chat_command("shoottime", "to modify the cooldown in between shots", on_shoottime_command)
hook_chat_command("warpammo", "[on|off] turn ammo regeneration on warp on or off", on_warpammo_command)
hook_chat_command("kill", "to set your health 0", on_kill_command)
hook_chat_command("refill", "to refill your ammo supply", on_refill_command)