# Agent X's Mod Writing Conventions (WIP)

## Naming Conventions:

### Mod Codename:
Come up with an acronym for your mod name, this will its codename.

Examples:
| Name | Acronym |
| ---- | ------- |
| Underworld | UW |
| Day Night Cycle | DNC |
| Weather Cycle | WC |
| Gun Mod | GM |

### Fundamental Code:
* **Functions:** snake_case (`function_name()`)
* **Variables:** camelCase (`variableName`)
* **Local Tables:** camelCase (`sLocalTable`)
* **Global Tables:** camelCase (`gGlobalTable`)

### SMLua Types
* **ModelExtendedId:** `E_MODEL_*`
* **TextureInfo:** `TEX_*`
* **BassAudio:** `SOUND_CUSTOM_*` or `STREAM_*` depending on whether or not you're loading a stream.

### Files:
Prefix actors, behaviors and textures with your mod codename. This is so other mods with files of the same name don't get the game confused, it's also just good practice. Levels and sounds do not need to adhere to this naming convention because other mods can't access them anyway.

Examples:
* **Actor Example:** `uw_skybox_geo.bin`
* **Behavior Example:** `bhvUWSkybox.bhv`
* **Texture Example:** `uw_intro_screen.tex`

### Referencing Files In Code:
When declaring model IDs and textures using `smlua_model_util_get_id` and `get_texture_info` respectively, drop the codename so it looks something like `E_MODEL_SKYBOX` or `TEX_INTRO_SCREEN` without the acronym.
* Tip: Think of this naming convention like you're only trying to prefix whatever other mods could see or interfere with.

## Practices

Make everything local as much as reasonably possible. local variables, local tables, local functions. Lua can reference these different types of data quicker than it would globally.

There is also I process I go through to optimize my mods even further this way. I have written a script that references a list of functions in the SMLua API and generates an `optimizations.lua` file that contains a line that localizes all of the functions for each file in the mod.
```sh
python utils/lua_optimizer.py mods/mod-name
```

Once you obtain this output file, you can paste the optimization lines into each one of the mod's files.

## Structure

I typically structure my mods with a constants file and a utility functions file. These are executed first because they are prefixed with `a-`.

* `a-constants.lua`: This file contains level IDs, model IDs, textures, sounds, actions and mod related constants.

* `a-utils.lua`: This file contains all utility functions used by the mod.

* `main.lua`: This file is the entry point of the mod, it contains the name, description, incompatibility tags, deluxe tag and pausable tag. I usually put vital hooks, variables and functions in this file.

* Other Lua Files: These files contain different components or systems that are in the mod. For example, Underworld has files such as `cutscene.lua`, `dialog.lua`, `npc.lua`.