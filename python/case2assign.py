import re

input_file = 'cos_lut_case.txt'   # 输入case语句文件
output_file = 'cos_lut_assign.txt' # 输出assign语句文件

with open(input_file, 'r', encoding='utf-8') as fin, open(output_file, 'w', encoding='utf-8') as fout:
    for line in fin:
        # 匹配 12'dN: cos_out = 16'sdXXXX;
        m = re.match(r"\s*12'd(\d+):\s*cos_out\s*=\s*([-\d'sd]+);", line)
        if m:
            idx, val = m.groups()
            fout.write(f"assign cos_val[{idx}] = {val};\n")