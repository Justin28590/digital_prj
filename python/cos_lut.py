import math

DEPTH = 1025  
WIDTH = 12
AMPLITUDE = 4095

with open('cos_lut_assign_0_512.v', 'w') as f:
    for c in range(DEPTH):
        val = int(round(math.cos(2*math.pi*c/4096) * AMPLITUDE))
        f.write(f"assign cos_vaL[{c}] = 12'd{val};\n")