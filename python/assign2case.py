import re

input_file = "cos_lut.v"
output_file = "cos_lut_case.v"

with open(input_file, "r", encoding="utf-8") as fin:
    lines = fin.readlines()

assign_lines = []
other_lines = []
for line in lines:
    m = re.match(r'\s*assign\s+cos_val\[(\d+)\]\s*=\s*(13\'d\d+);', line)
    if m:
        assign_lines.append((int(m.group(1)), m.group(2)))
    else:
        other_lines.append(line)

# 生成 always 块
always_block = []
always_block.append("always @* begin\n")
always_block.append("    case(idx)\n")
for idx, val in assign_lines:
    always_block.append(f"        {idx}: cos_val_reg = {val};\n")
always_block.append("        default: cos_val_reg = 13'd0;\n")
always_block.append("    endcase\n")
always_block.append("end\n")

# 插入 always 块到合适位置（这里简单写到文件末尾）
with open(output_file, "w", encoding="utf-8") as fout:
    for line in other_lines:
        fout.write(line)
    fout.write("\n// --- LUT implemented as always/case ---\n")
    fout.write("reg signed [12:0] cos_val_reg;\n")
    fout.writelines(always_block)
    fout.write("assign cos_out = sign ? -cos_val_reg : cos_val_reg;\n")