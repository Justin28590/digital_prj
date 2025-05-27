# 该脚本将分段内容自动转为Verilog格式，并带注释

with open('div_lut_17.txt', 'r', encoding='utf-8') as f:
    lines = [line.strip() for line in f if ':' in line]

# 只处理分段
start_idx = 600  # 分段起始行号（从0开始）
segment_size = 80  # 分段长度

# 取出分段数据
seg_lines = lines[start_idx:start_idx+segment_size]
seg_vals = [int(line.split(':')[1].split()[0]) for line in seg_lines]


print(f"/********************************************************************************/")
print(f"//第9段")

# 输出Verilog格式
print(f"assign val_base[9] = 17'd{seg_vals[0]};  // {start_idx+1}\n")

# 输出 wire 声明
print(f"wire [4:0] base9_offset [0:{segment_size-1}];  // {segment_size}项")
for i, v in enumerate(seg_vals):
    offset = seg_vals[0] - v
    line_num = start_idx + 1 + i
    print(f"assign base9_offset[{i}] = 5'd{offset};  // {seg_vals[0]}-{v}, {line_num}")