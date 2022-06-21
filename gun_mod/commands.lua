E_MODEL_GORDON = smlua_model_util_get_id("gordon_geo")

function on_inf_ammo_command(msg)
    if not network_is_server() then
        return false
    end

    if msg == "off" then
        gGlobalSyncTable.infAmmo = false
        djui_chat_message_create("Infinite ammo status: \\#FF0000\\OFF")
    else
        gGlobalSyncTable.infAmmo = true
        djui_chat_message_create("Infinite ammo status: \\#00ff00\\ON")
    end
    return true
end

function on_warp_ammo_command(msg)
    if not network_is_server() then
        return false
    end

    if msg == "off" then
        gGlobalSyncTable.warpAmmo = false
        djui_chat_message_create("Regenerate ammo on warp status: \\#FF0000\\OFF")
    else
        gGlobalSyncTable.warpAmmo = true
        djui_chat_message_create("Regenerate ammo on warp status: \\#00ff00\\ON")
    end
    return true
end

function on_kill_command()
    gMarioStates[0].health = 0xff
    return true
end

function on_reload_command()
    if get_ammo() == weaponTable[gPlayerSyncTable[0].weapon].maxAmmo then
        return true
    end
    reloadTimer = reloadTimer - get_ammo()
    set_ammo(0)
    return true
end

function on_gordon_command(msg)
    if msg == "off" then
        gPlayerSyncTable[0].modelId = nil
        djui_chat_message_create("Gordon mode status: \\#FF0000\\OFF")
    else
        gPlayerSyncTable[0].modelId = E_MODEL_GORDON
        djui_chat_message_create("Gordon mode \\#ffff00\\(Based)\\#ffffff\\ status: \\#00ff00\\ON")
    end
    return true
end

local notified = false
fpCommandEnabled = false
function on_fp_command(msg)
    if (gMarioStates[0].input & INPUT_FIRST_PERSON) ~= 0 then
        djui_chat_message_create("\\#ff0000\\Exit SM64's first person mode first!")
        play_sound(SOUND_MENU_CAMERA_BUZZ, gMarioStates[0].marioObj.header.gfx.cameraToObject)
        return true
    end

    if msg == "off" then
        disable_fp()
        fpCommandEnabled = false
        djui_chat_message_create("First person mode status: \\#FF0000\\OFF")
    else
        enable_fp()
        fpCommandEnabled = true
        djui_chat_message_create("First person mode status: \\#00ff00\\ON")
        if notified == false then
            notified = true
            djui_popup_create("\
Gun Mod - \\#1000ff\\First Person Testing Initiative\
\
\\#ffffff\\Welcome to the \\#ffff00\\W.I.P\\#ffffff\\ first person camera system.\
\\#ffff00\\Ensure free camera is disabled before playing.\\#ffffff\\\
\
You can use the mouse for camera movement as well as the right stick and rebind the keyboard controls to your liking as well.\
\
Please report any bugs you find\
and after 9 years in development hopefully it will be worth the wait.", 15)
        end
    end
    return true
end

function on_bhop_auto_command(msg)
    if not network_is_server() then
        return false
    end

    if msg == "off" then
        gGlobalSyncTable.autoBh = false
        djui_chat_message_create("Auto bhop status: \\#FF0000\\OFF")
    else
        gGlobalSyncTable.autoBh = true
        djui_chat_message_create("Auto bhop status: \\#00ff00\\ON")
    end
    return true
end

function on_bhop_command(msg)
    if not network_is_server() then
        return false
    end

    if msg == "off" then
        gGlobalSyncTable.bhop = false
        djui_chat_message_create("Bhop status: \\#FF0000\\OFF")
    else
        gGlobalSyncTable.bhop = true
        djui_chat_message_create("Bhop status: \\#00ff00\\ON")
    end
    return true
end

function on_fov_command(msg)
    if tonumber(msg) then
        djui_chat_message_create("FOV set to " .. msg)
        set_override_fov(tonumber(msg))
    else
        djui_chat_message_create("\\#ff0000\\Failed to set FOV to " .. msg)
    end
    return true
end

hook_chat_command("inf_ammo", "[on|off] turn infinite ammo on or off, default is \\#00ff00\\ON", on_inf_ammo_command)
hook_chat_command("warp_ammo", "[on|off] turn ammo regeneration on warp on or off, default is \\#00ff00\\ON", on_warp_ammo_command)
hook_chat_command("kill", "to set your health 0", on_kill_command)
hook_chat_command("reload", "to reload your gun", on_reload_command)
hook_chat_command("gordon", "[on|off] become Freeman, default is \\#FF0000\\OFF", on_gordon_command)
hook_chat_command("fp","[on|off] turn first person mode on or off, default is \\#FF0000\\OFF", on_fp_command)
hook_chat_command("bhop", "[on|off] turn bunny hop on or off, default is \\#00ff00\\ON", on_bhop_command)
hook_chat_command("bhop_auto", "[on|off] turn auto bhop (hold down A) on or off, default is \\#00ff00\\ON", on_bhop_auto_command)
hook_chat_command("fov", "[number (1-90 preferrably)] set your FOV to a new value, default is \\#ffff00\\0 (no override)", on_fov_command)