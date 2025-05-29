DEPTH = 8192  # 1~8190 共8190个数据
WIDTH = 21
MAX_VAL = (1 << WIDTH) - 1

with open('div_lut.v', 'w') as f:
    for i in range(1 , DEPTH -1):
        val = int(round(MAX_VAL / i))
        f.write(f"assign div_val[{i}] = 21'd{val};\n")