import sys

partNames = [
    "pants",
    "shirt",
    "gloves",
    "shoes",
    "hair",
    "skin",
    "cap",
    "metal" # custom
]

metalPart = "metal"

def get_parameter(argIndex, message, optional):
    returnValue = ""
    if len(sys.argv) > argIndex:
        returnValue = sys.argv[argIndex]
    elif not optional:
        returnValue = input(message)
    return returnValue

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--help":
        print('Example: python recolor_model.py "path/to/model.inc.c"')
        return
    
    path = get_parameter(1, "Enter path to model.inc.c: ", False)

    out = []
    with open(path, "r") as f:
        lines = f.readlines()

        for line in lines:
            for part in partNames:
                for i in range(1, 5):
                    light = f"gsSPSetLights1(mario_{part}{i if i > 1 else ''}_lights),"
                    if light in line:
                        line = line.replace(light, f"gsSPCopyLightsPlayerPart({part.upper()}),").replace("METAL", metalPart.upper())
            out.append(line)

    with open(path, "w") as f:
        f.write("".join(out))

main()