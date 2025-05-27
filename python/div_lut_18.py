DEPTH = 8190  # 1~8190 共8190个数据
WIDTH = 17
MAX_VAL = (1 << WIDTH) - 1

with open('div_lut_17.txt', 'w') as f:
    for i in range(1, DEPTH + 1):
        val = int(round(MAX_VAL / i))
        f.write(f"{i}: {val}\n")