import sys
import re

print("C To Lua Script")
print("Warning: you will need to edit the output, this just automates all of the little annoying bits.")

cli = True
path = ""
# smart arg handler
if len(sys.argv) > 1:
    path = sys.argv[1]
else:
    cli = False
    path = input("Type the path to the Lua file here: ")

out = ""
with open(path, "r") as f:
    floatPattern = re.compile(r"([-+]?(\d*\.\d+|\d+\.)([eE][-+]?\d+)?)[fF]")
    operatorPattern = re.compile(r"([a-zA-Z_][a-zA-Z0-9_]*)\s*\*=\s*([^;]*)")

    contents = f.read()

    # float correction
    contents = floatPattern.sub(r"\1", contents)

    # basic syntax corrections
    contents = contents.replace("->", ".")\
    .replace("else if", "elseif")\
    .replace("if (", "if ")\
    .replace("switch ", "switch")\
    .replace("}", "end")\
    .replace("end elseif", "elseif")\
    .replace("end else", "else")\
    .replace("else {", "else")\
    .replace("sqrt", "math.sqrt")\
    .replace("&&", "and")\
    .replace("||", "or")\
    .replace("[0]", ".x")\
    .replace("[1]", ".y")\
    .replace("[2]", ".z")\
    .replace(".0", "")\
    .replace("FALSE", "0")\
    .replace("TRUE", "1")\
    .replace("!=", "~=")\
    .replace("NULL", "nil")\
    .replace("//", "--")

    # half assed switch statement corrections
    contents = contents.replace("case ", "[")
    contents = contents.replace(":", "] = function()")
    contents = contents.replace("    break", "end,")

    # line specific corrections
    lines = contents.split("\n")
    newFunction = False
    for line in lines:
        # ignore #if, #ifdef, #ifndef, #else and #endif
        if line.startswith("#if") or line.startswith("#else") or line.startswith("#endif"):
            continue
        
        # type corrections
        for type in ["    u8", "    s8", "    u16", "    s16", "    u32", "    s32", "    f32"]:
            if type in line:
                cast = f"({type})"
                if cast in line:
                    line = line.replace(cast, type)
                else:
                    line = line.replace(type, "    local")

        # function declaration param correction
        for type in ["u8", "s8", "u16", "s16", "u32", "s32", "f32", "void"]:
            if line.startswith(type):
                line = line.replace(type, "local function")
                line = line.replace(") {", ")")
                if "MarioState" in line:
                    line = "--- @param m MarioState\n" + line
                line = re.sub(r"struct.*?\*", "", line)

        # if and switch statement corrections
        if "if" in line and line.endswith(") {"):
            line = line.replace(") {", " then")
        elif "switch" in line and line.endswith(") {"):
            line = line.replace(") {", ", {")

        # specific switch statement corrections, hacky
        if newFunction and "    end" in line:
            line = line.replace("end", "})")
        newFunction = "end," in line

        # vec3f correction
        if "Vec3f" in line:
            line = line.replace("Vec3f", "local").replace(";", " = { x = 0, y = 0, z = 0 }")

        if line.endswith(";"):
            line = line.replace(";", "")

        out += line + "\n"
with open(path.replace(".lua", "").replace(".c", "") + "_out.lua", "w") as f:
    f.write(out)
    
if not cli:
    input("Done! Press any key to exit. ")