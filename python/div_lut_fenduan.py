start_line = 1183  # 第1184行，索引从0开始
base_idx = 11      # val_base的起始索引

with open('div_lut_18.txt', 'r', encoding='utf-8') as f:
    lines = [line.strip() for line in f if ':' in line]

last_val = None
for i, line in enumerate(lines[start_line:], start=start_line):
    val = int(line.split(':')[1].split()[0])
    if val != last_val:
        print(f"assign val_base[{base_idx}] = 18'd{val};  // base of segment {base_idx}, from line {i+1}")
        last_val = val
        base_idx += 1