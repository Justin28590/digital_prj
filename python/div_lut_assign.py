DEPTH = 8191  # 0~8190 共8191个数据
WIDTH = 15
MAX_VAL = (1 << WIDTH) - 1

with open('div_lut_assign_0_8190_merged.v', 'w') as f:
    last_val = None
    start_idx = 0
    for i in range(DEPTH):
        if i == 0:
            val = MAX_VAL
        else:
            val = int(round(MAX_VAL / i))
        if last_val is None:
            last_val = val
            start_idx = i
        elif val != last_val:
            if start_idx == i-1:
                f.write(f"assign val[{start_idx}] = 15'd{last_val};   // {start_idx}\n")
            else:
                f.write(f"assign val[{start_idx}] = 15'd{last_val};   // {start_idx}-{i-1}\n")
            last_val = val
            start_idx = i
    # 写最后一段
    if start_idx == DEPTH-1:
        f.write(f"assign val[{start_idx}] = 15'd{last_val};   // {start_idx}\n")
    else:
        f.write(f"assign val[{start_idx}] = 15'd{last_val};   // {start_idx}-{DEPTH-1}\n")