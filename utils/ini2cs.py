import sys

partNames = [
    "PANTS",
    "SHIRT",
    "GLOVES",
    "SHOES",
    "HAIR",
    "SKIN",
    "CAP",
    "EMBLEM"
]

parts = {
    "PANTS_R": 0,
    "PANTS_G": 0,
    "PANTS_B": 0,
    "SHIRT_R": 0,
    "SHIRT_G": 0,
    "SHIRT_B": 0,
    "GLOVES_R": 0,
    "GLOVES_G": 0,
    "GLOVES_B": 0,
    "SHOES_R": 0,
    "SHOES_G": 0,
    "SHOES_B": 0,
    "HAIR_R": 0,
    "HAIR_G": 0,
    "HAIR_B": 0,
    "SKIN_R": 0,
    "SKIN_G": 0,
    "SKIN_B": 0,
    "CAP_R": 0,
    "CAP_G": 0,
    "CAP_B": 0,
    "EMBLEM_R": 0,
    "EMBLEM_G": 0,
    "EMBLEM_B": 0
}

def to_hex(value):
    return f"0x{value:02x}"

with open(sys.argv[1], "r") as f:
    for line in f.readlines():
        if line.startswith("["):
            continue
            
        for part in parts:
            if line.startswith(part):
                parts[part] = to_hex(int(line.split("=")[1].replace(" ", "")))

with open("cs_palette.txt", "w") as f:
    f.write("{\n")
    for part in partNames:
        colors = "{ " + f"r = {parts[part + "_R"]}, g = {parts[part + "_G"]}, b = {parts[part + "_B"]}" + " },"
        f.write(f"    [{part}] = {colors}\n")
    f.write("}")