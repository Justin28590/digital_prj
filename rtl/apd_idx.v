module apd_idx(
    input wire [12:0] apd,           // APD输入值 (1-8190)
    output reg [3:0] segment_type,  // 段类型：0=base_self, 1=seg0, 2=seg1, ..., 11=seg10, 12=direct
    output reg [6:0] offset,        // 段内偏移量
    output reg [7:0] idx_out         // 二分法索引输出
);

// 段类型定义
localparam SEG_BASE      = 4'd0;   // val_base_self表
localparam SEG_1         = 4'd1;   // base1_offset表
localparam SEG_2         = 4'd2;   // base2_offset表
localparam SEG_3         = 4'd3;   // base3_offset表
localparam SEG_4         = 4'd4;   // base4_offset表
localparam SEG_5         = 4'd5;   // base5_offset表
localparam SEG_6         = 4'd6;   // base6_offset表
localparam SEG_7         = 4'd7;   // base7_offset表
localparam SEG_8         = 4'd8;   // base8_offset表
localparam SEG_9         = 4'd9;   // base9_offset表
localparam SEG_DIRECT     = 4'd10;  // 直接查val_base表

// 段边界判断信号（组合逻辑）- 优化版本
// 利用段边界递增特性，减少比较次数
wire [12:0] boundaries [0:11];
assign boundaries[0]  = 13'd1;    // base_self: apd-1
assign boundaries[1]  = 13'd91;   
assign boundaries[2]  = 13'd155;  
assign boundaries[3]  = 13'd219;  
assign boundaries[4]  = 13'd283;  
assign boundaries[5]  = 13'd347;  
assign boundaries[6]  = 13'd411;  
assign boundaries[7]  = 13'd475;  
assign boundaries[8]  = 13'd537;  
assign boundaries[9]  = 13'd601;  
assign boundaries[10]  = 13'd673;  
assign boundaries[11]  = 13'd8190;  


// 简化的段选择逻辑
wire sel_base       = (apd >= boundaries[0]) && (apd <= boundaries[1]);
wire sel_seg1       = (apd > boundaries[1]) && (apd <= boundaries[2]);
wire sel_seg2       = (apd > boundaries[2]) && (apd <= boundaries[3]);
wire sel_seg3       = (apd > boundaries[3]) && (apd <= boundaries[4]);
wire sel_seg4       = (apd > boundaries[4]) && (apd <= boundaries[5]);
wire sel_seg5       = (apd > boundaries[5]) && (apd <= boundaries[6]);
wire sel_seg6       = (apd > boundaries[6]) && (apd <= boundaries[7]);
wire sel_seg7       = (apd > boundaries[7]) && (apd <= boundaries[8]);
wire sel_seg8       = (apd > boundaries[8]) && (apd <= boundaries[9]);
wire sel_seg9       = (apd > boundaries[9]) && (apd <= boundaries[10]);
wire sel_direct     = (apd > boundaries[10]) && (apd <= boundaries[11]);



// 组合逻辑计算段类型和偏移量
reg [3:0] segment_type_comb;
wire [6:0] offset_comb;    

// 使用优先编码器函数 - 更简洁的写法
always @(*) begin
    if (sel_direct)         segment_type_comb = SEG_DIRECT;
    else if (sel_seg9)      segment_type_comb = SEG_9;
    else if (sel_seg8)      segment_type_comb = SEG_8;
    else if (sel_seg7)      segment_type_comb = SEG_7;
    else if (sel_seg6)      segment_type_comb = SEG_6;
    else if (sel_seg5)      segment_type_comb = SEG_5;
    else if (sel_seg4)      segment_type_comb = SEG_4;
    else if (sel_seg3)      segment_type_comb = SEG_3;
    else if (sel_seg2)      segment_type_comb = SEG_2;
    else if (sel_seg1)      segment_type_comb = SEG_1;
    else if (sel_base)      segment_type_comb = SEG_BASE;
    else                    segment_type_comb = 4'd15; // 错误标志
end

assign offset_comb = apd - boundaries[segment_type_comb]; 

always @(*) begin
    segment_type = segment_type_comb;
    offset = offset_comb;
end

//二分法的索引
wire [12:0] val_seg [0:178]; 
assign val_seg[0] = 13'd674;
assign val_seg[1] = 13'd678;
assign val_seg[2] = 13'd681;
assign val_seg[3] = 13'd685;
assign val_seg[4] = 13'd689;
assign val_seg[5] = 13'd692;
assign val_seg[6] = 13'd696;
assign val_seg[7] = 13'd700;
assign val_seg[8] = 13'd703;
assign val_seg[9] = 13'd707;
assign val_seg[10] = 13'd711;
assign val_seg[11] = 13'd715;
assign val_seg[12] = 13'd719;
assign val_seg[13] = 13'd723;
assign val_seg[14] = 13'd727;
assign val_seg[15] = 13'd731;
assign val_seg[16] = 13'd735;
assign val_seg[17] = 13'd739;
assign val_seg[18] = 13'd743;
assign val_seg[19] = 13'd747;
assign val_seg[20] = 13'd752;
assign val_seg[21] = 13'd756;
assign val_seg[22] = 13'd760;
assign val_seg[23] = 13'd765;
assign val_seg[24] = 13'd769;
assign val_seg[25] = 13'd774;
assign val_seg[26] = 13'd778;
assign val_seg[27] = 13'd783;
assign val_seg[28] = 13'd788;
assign val_seg[29] = 13'd792;
assign val_seg[30] = 13'd797;
assign val_seg[31] = 13'd802;
assign val_seg[32] = 13'd807;
assign val_seg[33] = 13'd812;
assign val_seg[34] = 13'd817;
assign val_seg[35] = 13'd822;
assign val_seg[36] = 13'd827;
assign val_seg[37] = 13'd833;
assign val_seg[38] = 13'd838;
assign val_seg[39] = 13'd843;
assign val_seg[40] = 13'd849;
assign val_seg[41] = 13'd854;
assign val_seg[42] = 13'd860;
assign val_seg[43] = 13'd866;
assign val_seg[44] = 13'd871;
assign val_seg[45] = 13'd877;
assign val_seg[46] = 13'd883;
assign val_seg[47] = 13'd889;
assign val_seg[48] = 13'd895;
assign val_seg[49] = 13'd901;
assign val_seg[50] = 13'd908;
assign val_seg[51] = 13'd914;
assign val_seg[52] = 13'd920;
assign val_seg[53] = 13'd927;
assign val_seg[54] = 13'd933;
assign val_seg[55] = 13'd940;
assign val_seg[56] = 13'd947;
assign val_seg[57] = 13'd954;
assign val_seg[58] = 13'd961;
assign val_seg[59] = 13'd968;
assign val_seg[60] = 13'd975;
assign val_seg[61] = 13'd982;
assign val_seg[62] = 13'd990;
assign val_seg[63] = 13'd997;
assign val_seg[64] = 13'd1005;
assign val_seg[65] = 13'd1013;
assign val_seg[66] = 13'd1021;
assign val_seg[67] = 13'd1029;
assign val_seg[68] = 13'd1037;
assign val_seg[69] = 13'd1045;
assign val_seg[70] = 13'd1053;
assign val_seg[71] = 13'd1062;
assign val_seg[72] = 13'd1070;
assign val_seg[73] = 13'd1079;
assign val_seg[74] = 13'd1088;
assign val_seg[75] = 13'd1097;
assign val_seg[76] = 13'd1107;
assign val_seg[77] = 13'd1116;
assign val_seg[78] = 13'd1126;
assign val_seg[79] = 13'd1135;
assign val_seg[80] = 13'd1145;
assign val_seg[81] = 13'd1155;
assign val_seg[82] = 13'd1166;
assign val_seg[83] = 13'd1176;
assign val_seg[84] = 13'd1187;
assign val_seg[85] = 13'd1197;
assign val_seg[86] = 13'd1209;
assign val_seg[87] = 13'd1220;
assign val_seg[88] = 13'd1231;
assign val_seg[89] = 13'd1243;
assign val_seg[90] = 13'd1255;
assign val_seg[91] = 13'd1267;
assign val_seg[92] = 13'd1279;
assign val_seg[93] = 13'd1292;
assign val_seg[94] = 13'd1305;
assign val_seg[95] = 13'd1318;
assign val_seg[96] = 13'd1331;
assign val_seg[97] = 13'd1345;
assign val_seg[98] = 13'd1359;
assign val_seg[99] = 13'd1373;
assign val_seg[100] = 13'd1387;
assign val_seg[101] = 13'd1402;
assign val_seg[102] = 13'd1417;
assign val_seg[103] = 13'd1433;
assign val_seg[104] = 13'd1449;
assign val_seg[105] = 13'd1465;
assign val_seg[106] = 13'd1482;
assign val_seg[107] = 13'd1498;
assign val_seg[108] = 13'd1516;
assign val_seg[109] = 13'd1533;
assign val_seg[110] = 13'd1552;
assign val_seg[111] = 13'd1570;
assign val_seg[112] = 13'd1589;
assign val_seg[113] = 13'd1609;
assign val_seg[114] = 13'd1629;
assign val_seg[115] = 13'd1649;
assign val_seg[116] = 13'd1670;
assign val_seg[117] = 13'd1692;
assign val_seg[118] = 13'd1714;
assign val_seg[119] = 13'd1737;
assign val_seg[120] = 13'd1760;
assign val_seg[121] = 13'd1784;
assign val_seg[122] = 13'd1808;
assign val_seg[123] = 13'd1834;
assign val_seg[124] = 13'd1860;
assign val_seg[125] = 13'd1886;
assign val_seg[126] = 13'd1914;
assign val_seg[127] = 13'd1942;
assign val_seg[128] = 13'd1971;
assign val_seg[129] = 13'd2002;
assign val_seg[130] = 13'd2033;
assign val_seg[131] = 13'd2065;
assign val_seg[132] = 13'd2098;
assign val_seg[133] = 13'd2132;
assign val_seg[134] = 13'd2167;
assign val_seg[135] = 13'd2203;
assign val_seg[136] = 13'd2241;
assign val_seg[137] = 13'd2280;
assign val_seg[138] = 13'd2320;
assign val_seg[139] = 13'd2362;
assign val_seg[140] = 13'd2405;
assign val_seg[141] = 13'd2450;
assign val_seg[142] = 13'd2497;
assign val_seg[143] = 13'd2546;
assign val_seg[144] = 13'd2596;
assign val_seg[145] = 13'd2648;
assign val_seg[146] = 13'd2703;
assign val_seg[147] = 13'd2760;
assign val_seg[148] = 13'd2819;
assign val_seg[149] = 13'd2881;
assign val_seg[150] = 13'd2946;
assign val_seg[151] = 13'd3014;
assign val_seg[152] = 13'd3085;
assign val_seg[153] = 13'd3159;
assign val_seg[154] = 13'd3237;
assign val_seg[155] = 13'd3319;
assign val_seg[156] = 13'd3405;
assign val_seg[157] = 13'd3496;
assign val_seg[158] = 13'd3591;
assign val_seg[159] = 13'd3693;
assign val_seg[160] = 13'd3800;
assign val_seg[161] = 13'd3913;
assign val_seg[162] = 13'd4033;
assign val_seg[163] = 13'd4161;
assign val_seg[164] = 13'd4298;
assign val_seg[165] = 13'd4444;
assign val_seg[166] = 13'd4599;
assign val_seg[167] = 13'd4767;
assign val_seg[168] = 13'd4947;
assign val_seg[169] = 13'd5141;
assign val_seg[170] = 13'd5350;
assign val_seg[171] = 13'd5578;
assign val_seg[172] = 13'd5826;
assign val_seg[173] = 13'd6097;
assign val_seg[174] = 13'd6394;
assign val_seg[175] = 13'd6722;
assign val_seg[176] = 13'd7085;
assign val_seg[177] = 13'd7490;
assign val_seg[178] = 13'd7944;


// 假设N=179，分成13段，段界点如下（示例索引）
localparam Q0 = 0;
localparam Q1 = 13;
localparam Q2 = 26;
localparam Q3 = 39;
localparam Q4 = 52;
localparam Q5 = 65;
localparam Q6 = 78;
localparam Q7 = 91;
localparam Q8 = 104;
localparam Q9 = 117;
localparam Q10 = 130;
localparam Q11 = 143;
localparam Q12 = 156;
localparam Q13 = 178;  // 最后一段结尾

integer i;
reg found_flag;

always @(*) begin
    idx_out = 0; 
    found_flag = 0;

    if (apd < val_seg[Q1]) begin
        for (i = Q0; i <= Q1; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q2]) begin
        for (i = Q1 + 1; i <= Q2; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q3]) begin
        for (i = Q2 + 1; i <= Q3; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q4]) begin
        for (i = Q3 + 1; i <= Q4; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q5]) begin
        for (i = Q4 + 1; i <= Q5; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q6]) begin
        for (i = Q5 + 1; i <= Q6; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q7]) begin
        for (i = Q6 + 1; i <= Q7; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q8]) begin
        for (i = Q7 + 1; i <= Q8; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q9]) begin
        for (i = Q8 + 1; i <= Q9; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q10]) begin
        for (i = Q9 + 1; i <= Q10; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q11]) begin
        for (i = Q10 + 1; i <= Q11; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else if (apd < val_seg[Q12]) begin
        for (i = Q11 + 1; i <= Q12; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end else begin
        for (i = Q12 + 1; i <= Q13; i = i + 1) begin
            if (!found_flag && val_seg[i] >= apd) begin
                idx_out = i-1;
                found_flag = 1;
            end
        end
    end
end


endmodule