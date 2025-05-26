import re

with open('div_lut_18.v', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# 提取 (idx, value, apd区间)
lut = []
for line in lines:
    m = re.match(r'assign val\[(\d+)\] = 18\'d(\d+);.*?//\s*([\d]+)(?:-([\d]+))?', line)
    if m:
        idx = int(m.group(1))
        val = int(m.group(2))
        apd_start = int(m.group(3))
        apd_end = int(m.group(4)) if m.group(4) else apd_start
        lut.append((idx, val, apd_start, apd_end))

# 按apd区间顺序展开，索引递增
final = []
for i, (idx, val, apd_start, apd_end) in enumerate(lut):
    if apd_start == apd_end:
        final.append(f"assign val[{i}] = 18'd{val};   // {apd_start}\n")
    else:
        final.append(f"assign val[{i}] = 18'd{val};   // {apd_start}-{apd_end}\n")

with open('final_lut_with_apd.v', 'w', encoding='utf-8') as fout:
    fout.writelines(final)