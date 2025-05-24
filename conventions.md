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

### Smlua Types
* **ModelExtendedId:** `E_MODEL_*`
* **TextureInfo:** `TEX_*`
* **BassAudio:** `SAMPLE_*` or `STREAM_*` depending on whether or not you're loading a stream.

### Files:
Prefix actors, behaviors and textures with your mod codename. This is so other mods with files of the same name don't get the game confused, it's also just good practice. Sounds do not need to adhere to this naming convention because other mods can't access them anyway.

Examples:
* **Actor Example:** `uw_skybox_geo.bin`
* **Behavior Example:** `bhvUWSkybox.bhv`
* **Texture Example:** `uw_intro_screen.tex`

## Practices

Make everything local as much as reasonably possible. local variables, local tables, local functions. Lua can reference these different types of data quicker than it would globally.

There is also I process I go through to optimize my mods even further this way. I have written a script that references a list of functions in the Smlua API and generates an `optimizations.lua` file that contains a line that localizes all of the functions for each file in the mod.
```sh
python utils/lua_optimizer.py mods/mod-name
```

Once you obtain this output file, you can paste the optimization lines into each one of the mod's files.

Another practice I have is that when I'm working with HUD rendering, any rendering property that's used or set (resolution, font, color, ect) is declared in the function. If I set the filter and font for example, I'm going to run this:
```lua
djui_hud_set_filter(FILTER_NEAREST)
djui_hud_set_font(FONT_HUD)
```

Before, you used to not be able to rely on default DJUI HUD values since they weren't reset between mods. I still think it's a good practice to explicitly set DJUI hud values so you know exactly how it's going to render and also to future proof it in case the defaults were to change for whatever reason in the future.

## Structure

I typically structure my mods with a constants file and a utility functions file. These are executed first because they are prefixed with `a-`.

* `a-constants.lua`: This file contains level IDs, model IDs, textures, sounds, actions and mod related constants.

* `a-utils.lua`: This file contains all utility functions used by the mod.

* `main.lua`: This file is the entry point of the mod, it contains the name, description, incompatibility tags, and pausable tag if necessary. I usually put vital hooks, variables and functions in this file as well as constants if the mod is small enough to not warrant making a whole file for them.

* Other Lua Files: These files contain different components or systems that are in the mod. For example, Underworld has files such as `cutscene.lua`, `dialog.lua`, `npc.lua`.

## Mod Storage 

In Mod Storage keys, I use snake_case for naming them.