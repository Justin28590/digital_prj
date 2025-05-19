import re

val_lines = []
with open('div_lut.v', encoding='utf-8') as f:
    for line in f:
        if 'assign val[' in line:
            val_lines.append(line.strip())

# 解析注释区间
idx_map = []
for line in val_lines:
    m = re.match(r'assign val\[(\d+)\] = .*//\s*([\d\-]+)', line)
    if not m:
        continue
    idx = int(m.group(1))
    comment = m.group(2)
    if '-' in comment:
        start, end = map(int, comment.split('-'))
    else:
        start = end = int(comment)
    idx_map.append((start, end, idx))

# 生成多行Verilog代码并写入文件
with open('idx_assign.v', 'w', encoding='utf-8') as f:
    f.write('assign idx = (apd < {}) ? apd :\n'.format(idx_map[0][0]))
    for i, (start, end, idx) in enumerate(idx_map):
        if start < idx_map[0][0]:
            continue  # 跳过apd<最小值的情况
        if start == end:
            f.write('    (apd < {}) ? {} :\n'.format(start+1, idx))
        else:
            f.write('    (apd < {}) ? {} :\n'.format(end+1, idx))
    f.write('    {};\n'.format(idx_map[-1][2]))