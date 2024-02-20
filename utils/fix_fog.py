import sys

model_data = ""
with open(sys.argv[1], "r") as f:
    model_data = f.read()
model_data = model_data.replace("gsDPSetCombineLERP(TEXEL0, 0, SHADE, 0, 0, 0, 0, ENVIRONMENT, 0, 0, 0, COMBINED, 0, 0, 0, COMBINED),", "gsDPSetCombineMode(G_CC_MODULATEI, G_CC_PASS2),")
with open(sys.argv[1], "w") as f:
    f.write(model_data)
