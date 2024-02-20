import os
import sys
import shutil

colors = {
    "default": '\033[37m',
    "purple": '\033[95m',
    "blue": '\033[94m',
    "cyan": '\033[96m',
    "green": '\033[92m',
    "red": '\033[91m',
}

mode = "Compilation" if sys.argv[2] == "--compile" else "Merging" 

print(f"{colors.get('blue')}sm64ex-coop Lua Folder Mod Merger\n{colors.get('cyan')}By Agent X\n{colors.get('purple')}Mode: {mode}{colors.get('default')}")

info = ""
code = ""

for filename in os.listdir(sys.argv[1]):
    if filename.endswith(".lua"):
        with open(sys.argv[1] + "/" + filename, "r") as f:
            try:
                for line in f.readlines():
                    if line.startswith("-- name:") or line.startswith("-- incompatible:") or line.startswith("-- description:"):
                        info += line
                    else:
                        code += line
                print(f"Merging {filename}...")
                code += "\n\n"
            except:
                print(f"{colors.get('red')}Failed to merge {filename}!{colors.get('default')}")

with open("merged.lua", "w") as f:
    f.write(info + "\n" + code)
    if mode == "Merging":
        print(f"{colors.get('green')}Done! (merged Lua file outputted in merged.lua){colors.get('default')}")
    else:
        os.system("luac.exe merged.lua")
        shutil.copyfile("luac.out", sys.argv[3] + "/out.lua")
        os.remove("luac.out")
        print(f"{colors.get('green')}Done! (compiled Lua file outputted in compile directory){colors.get('default')}")
        