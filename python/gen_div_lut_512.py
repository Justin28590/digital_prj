import re

infile = 'div_lut_assign_0_8190_merged.v'
outfile = 'div_lut_assign_0_8190_stepwise.v'

pattern = re.compile(r'assign val\[(\d+)\] = 12\'d(\d+);.*?//\s*(\d+)(?:-(\d+))?')

# 读取所有区间
ranges = []
with open(infile, 'r') as fin:
    for line in fin:
        m = pattern.search(line)
        if m:
            idx = int(m.group(1))
            val = int(m.group(2))
            start = int(m.group(3))
            end = int(m.group(4)) if m.group(4) else start
            comment = line[line.find('//'):].strip()
            ranges.append((start, end, val, comment))

# 生成stepwise
with open(outfile, 'w') as fout:
    for i in range(ranges[0][0], ranges[-1][1]+1):
        # 找到当前i属于哪个区间
        for j, (start, end, val, comment) in enumerate(ranges):
            if start <= i <= end:
                # 下一个区间的值
                next_val = ranges[j+1][2] if (j+1)<len(ranges) else val
                next_comment = ranges[j+1][3] if (j+1)<len(ranges) else comment
                break
        # 当前区间的起点用当前值和注释，其余用下一个区间的值和注释
        if any(i == start for (start, end, val, comment) in ranges):
            fout.write(f"assign val[{i}] = 12'd{val};   {comment}\n")
        else:
            fout.write(f"assign val[{i}] = 12'd{next_val};   {next_comment}\n")