module apd_idx(
    //input wire clk,
    //input wire rst_n,
    input wire [12:0] apd,          // APD输入值 (1-8190)
    output wire [3:0] segment_type,  // 段类型：0=base_self, 1=seg0, 2=seg1, ..., 11=seg10, 12=direct
    output wire [12:0] offset,       // 段内偏移量
    output wire valid                // 输出有效标志
);

// 段类型定义
localparam SEG_BASE_SELF = 4'd0;   // val_base_self表
localparam SEG_0         = 4'd1;   // base0_offset表
localparam SEG_1         = 4'd2;   // base1_offset表
localparam SEG_2         = 4'd3;   // base2_offset表
localparam SEG_3         = 4'd4;   // base3_offset表
localparam SEG_4         = 4'd5;   // base4_offset表
localparam SEG_5         = 4'd6;   // base5_offset表
localparam SEG_6         = 4'd7;   // base6_offset表
localparam SEG_7         = 4'd8;   // base7_offset表
localparam SEG_8         = 4'd9;   // base8_offset表
localparam SEG_9         = 4'd10;  // base9_offset表
localparam SEG_10        = 4'd11;  // base10_offset表
localparam SEG_DIRECT    = 4'd12;  // 直接查val_base表

// 段边界判断信号（组合逻辑）- 优化版本
// 利用段边界递增特性，减少比较次数
wire [12:0] boundaries [0:12];
assign boundaries[0]  = 13'd125;   // base_self上边界
assign boundaries[1]  = 13'd142;   // seg0上边界
assign boundaries[2]  = 13'd166;   // seg1上边界
assign boundaries[3]  = 13'd199;   // seg2上边界
assign boundaries[4]  = 13'd248;   // seg3上边界
assign boundaries[5]  = 13'd328;   // seg4上边界
assign boundaries[6]  = 13'd484;   // seg5上边界
assign boundaries[7]  = 13'd633;   // seg6上边界
assign boundaries[8]  = 13'd750;   // seg7上边界
assign boundaries[9]  = 13'd918;   // seg8上边界
assign boundaries[10] = 13'd1034;  // seg9上边界
assign boundaries[11] = 13'd1183;  // seg10上边界
assign boundaries[12] = 13'd8190;  // direct上边界

// 简化的段选择逻辑
wire sel_base_self  = (apd >= 14'd1) && (apd <= boundaries[0]);
wire sel_seg0       = (apd > boundaries[0]) && (apd <= boundaries[1]);
wire sel_seg1       = (apd > boundaries[1]) && (apd <= boundaries[2]);
wire sel_seg2       = (apd > boundaries[2]) && (apd <= boundaries[3]);
wire sel_seg3       = (apd > boundaries[3]) && (apd <= boundaries[4]);
wire sel_seg4       = (apd > boundaries[4]) && (apd <= boundaries[5]);
wire sel_seg5       = (apd > boundaries[5]) && (apd <= boundaries[6]);
wire sel_seg6       = (apd > boundaries[6]) && (apd <= boundaries[7]);
wire sel_seg7       = (apd > boundaries[7]) && (apd <= boundaries[8]);
wire sel_seg8       = (apd > boundaries[8]) && (apd <= boundaries[9]);
wire sel_seg9       = (apd > boundaries[9]) && (apd <= boundaries[10]);
wire sel_seg10      = (apd > boundaries[10]) && (apd <= boundaries[11]);
wire sel_direct     = (apd > boundaries[11]) && (apd <= boundaries[12]);
wire out_of_range   = (apd == 13'd0)；


// 组合逻辑计算段类型和偏移量
wire [3:0] segment_type_comb;
wire [12:0] offset_comb;    //需要支持后面很大情况下直接查表的13位偏移量

// 使用优先编码器函数 - 更简洁的写法
always @(*) begin
    if (sel_direct)         segment_type_comb = SEG_DIRECT;
    else if (sel_seg10)     segment_type_comb = SEG_10;
    else if (sel_seg9)      segment_type_comb = SEG_9;
    else if (sel_seg8)      segment_type_comb = SEG_8;
    else if (sel_seg7)      segment_type_comb = SEG_7;
    else if (sel_seg6)      segment_type_comb = SEG_6;
    else if (sel_seg5)      segment_type_comb = SEG_5;
    else if (sel_seg4)      segment_type_comb = SEG_4;
    else if (sel_seg3)      segment_type_comb = SEG_3;
    else if (sel_seg2)      segment_type_comb = SEG_2;
    else if (sel_seg1)      segment_type_comb = SEG_1;
    else if (sel_seg0)      segment_type_comb = SEG_0;
    else if (sel_base_self) segment_type_comb = SEG_BASE_SELF;
    else                    segment_type_comb = 4'd15; // 错误标志
end

// 偏移量计算 - 使用查找表方式
wire [12:0] base_offsets [0:12];
assign base_offsets[0]  = 13'd1;    // base_self: apd-1
assign base_offsets[1]  = 13'd126;  // seg0: apd-126
assign base_offsets[2]  = 13'd143;  // seg1: apd-143
assign base_offsets[3]  = 13'd167;  // seg2: apd-167
assign base_offsets[4]  = 13'd200;  // seg3: apd-200
assign base_offsets[5]  = 13'd249;  // seg4: apd-249
assign base_offsets[6]  = 13'd329;  // seg5: apd-329
assign base_offsets[7]  = 13'd485;  // seg6: apd-485
assign base_offsets[8]  = 13'd634;  // seg7: apd-634
assign base_offsets[9]  = 13'd751;  // seg8: apd-751
assign base_offsets[10] = 13'd919;  // seg9: apd-919
assign base_offsets[11] = 13'd1035; // seg10: apd-1035
assign base_offsets[12] = 13'd1184; // direct: apd-1184

assign offset_comb = apd - base_offsets[segment_type_comb]; //这里如果offset=0：赋值为段起始值，offset=1才开始赋值为差值[0]

/*
// 时钟逻辑
always @(posedge clk) begin
    if (!rst_n) begin
        segment_type <= 4'd0;
        offset <= 13'd0;
        valid <= 1'b0;
    end else begin
        segment_type <= segment_type_comb;
        offset <= offset_comb;
        valid <= !out_of_range;
    end
end
*/

// 输出逻辑
assign segment_type = segment_type_comb;
assign offset = offset_comb;
assign valid = !out_of_range;


endmodule

// 使用示例说明：
// 根据输出的segment_type和offset，后续逻辑可以这样处理：
//
// case (segment_type)
//     SEG_BASE_SELF: div_val = val_base_self[offset];
//     SEG_0: div_val = val_base[0] - base0_offset[offset];
//     SEG_1: div_val = val_base[1] - base1_offset[offset];
//     ...
//     SEG_10: div_val = val_base[10] - base10_offset[offset];
//     SEG_DIRECT: div_val = val_base[11 + offset];  // offset范围0-189对应val_base[11-200]
//                                                   // offset > 189需要特殊处理
// endcase