E_MODEL_GORDON = smlua_model_util_get_id("gordon_geo")

function on_infammo_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return false
    end

    if msg == "on" then
        gGlobalSyncTable.infAmmo = true
        djui_chat_message_create("Infinite ammo on")
    else
        gGlobalSyncTable.infAmmo = false
        djui_chat_message_create("Infinite ammo off")
    end
    return true
end

function on_warpammo_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return false
    end

    if msg == "on" then
        gGlobalSyncTable.warpAmmo = true
        djui_chat_message_create("Regenerate ammo on warp on")
    else
        gGlobalSyncTable.warpAmmo = false
        djui_chat_message_create("Regenerate ammo on warp off")
    end
    return true
end

function on_kill_command()
    gMarioStates[0].health = 0xff
    return true
end

function on_reload_command()
    reloadTimer = reloadTimer - get_ammo(gMarioStates[0])
    set_ammo(gMarioStates[0], 0)
    return true
end

function on_gordon_command(msg)
    if not network_is_server() then
        djui_chat_message_create("You need to be the host!")
        return false
    end

    if msg == "on" then
        gPlayerSyncTable[0].modelId = E_MODEL_GORDON
    else
        gPlayerSyncTable[0].modelId = nil
    end
    return true
end

hook_chat_command("infammo", "[on|off] turn infinite ammo on or off", on_infammo_command)
hook_chat_command("warpammo", "[on|off] turn ammo regeneration on warp on or off", on_warpammo_command)
hook_chat_command("kill", "to set your health 0", on_kill_command)
hook_chat_command("reload", "to reload your gun", on_reload_command)
hook_chat_command("gordon", "[on|off] become Freeman.", on_gordon_command)