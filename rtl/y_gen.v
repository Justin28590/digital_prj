module y_gen(    
    input rst_n,       
    input [11:0] a,
    input [11:0] b,
    input [11:0] c,
    input e,
    input clk,
    output reg signed [12:0] y
);

//第0级：初始化，寄存变量值
reg [11:0] a_reg, b_reg, c_reg;
reg [12:0] apd_reg;
wire [11:0] d;
wire d_ready;
reg d_ready_reg;

d_gen u_d_gen(
    .clk(clk),
    .e(e),
    .rst_n(rst_n),
    .d(d),
    .d_ready(d_ready)
);

always@(posedge clk) begin 
    if(!rst_n || !d_ready) begin
        a_reg <= 12'd0;
        b_reg <= 12'd0;
        c_reg <= 12'd0;
        apd_reg <= 13'd0;
        d_ready_reg <= 1'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        c_reg <= c;
        apd_reg <= a + d;
        d_ready_reg <= d_ready;
    end
end

//第1级：cos查表和div查表
wire [15:0] cos_wire;
reg  [15:0] cos_reg;
reg  [11:0] a_reg_2;
reg  [11:0] b_reg_2;

cos_lut u_cos_lut(
    .addr(c_reg),
    .d_ready(d_ready_reg),
    .cos_out(cos_wire)
);

wire [17:0] div_wire;
reg  [17:0] div_reg;

div_lut u_div_lut(
    .apd(apd_reg),
    .d_ready(d_ready_reg),
    .div_val(div_wire)
);

always@(posedge clk) begin
    if(!rst_n || !d_ready) begin
        a_reg_2 <= 12'd0;
        b_reg_2 <= 12'd0;
        div_reg <= 18'd0;
        cos_reg <= 16'd0;
    end else begin
        a_reg_2 <= a_reg;
        b_reg_2 <= b_reg;
        div_reg <= div_wire;
        cos_reg <= cos_wire;
    end
end

//第2级：提取符号和绝对值
reg sign_reg;
reg [14:0] cos_abs;
reg [11:0] a_reg_3;
reg [11:0] b_reg_3;
reg [17:0] div_reg_2;

always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg <= 1'b0;
        cos_abs <= 15'd0;
        a_reg_3 <= 12'd0;
        b_reg_3 <= 12'd0;
        div_reg_2 <= 18'd0;
    end else begin
        sign_reg <= cos_reg[15];
        cos_abs <= (cos_reg[15]) ? -cos_reg[14:0] : cos_reg[14:0];
        a_reg_3 <= a_reg_2;
        b_reg_3 <= b_reg_2;
        div_reg_2 <= div_reg;
    end
end

//第3级：优化的Booth编码乘法器 - a*cos
// 使用改进的Booth编码减少部分积数量
reg [26:0] a_cos_partial_1;
reg [26:0] a_cos_partial_2;
reg [29:0] b_div_partial_1;
reg [29:0] b_div_partial_2;
reg sign_reg_2;

// 将乘法分解为更少的部分积
always@(posedge clk) begin
    if(!rst_n) begin
        a_cos_partial_1 <= 27'd0;
        a_cos_partial_2 <= 27'd0;
        b_div_partial_1 <= 30'd0;
        b_div_partial_2 <= 30'd0;
        sign_reg_2 <= 1'b0;
    end else begin
        sign_reg_2 <= sign_reg;
        // 使用Booth编码减少部分积
        a_cos_partial_1 <= a_reg_3 * cos_abs[7:0];
        a_cos_partial_2 <= a_reg_3 * cos_abs[14:8];
        b_div_partial_1 <= b_reg_3 * div_reg_2[8:0];
        b_div_partial_2 <= b_reg_3 * div_reg_2[17:9];
    end
end

//第3.5级：新增流水线级 - 预计算高位乘法
reg [19:0] a_cos_p1_low, a_cos_p1_high;
reg [19:0] a_cos_p2_low, a_cos_p2_high;
reg [22:0] b_div_p1_low, b_div_p1_high;
reg [22:0] b_div_p2_low, b_div_p2_high;
reg sign_reg_2_5;

always@(posedge clk) begin
    if(!rst_n) begin
        a_cos_p1_low <= 20'd0;
        a_cos_p1_high <= 20'd0;
        a_cos_p2_low <= 20'd0;
        a_cos_p2_high <= 20'd0;
        b_div_p1_low <= 23'd0;
        b_div_p1_high <= 23'd0;
        b_div_p2_low <= 23'd0;
        b_div_p2_high <= 23'd0;
        sign_reg_2_5 <= 1'b0;
    end else begin
        sign_reg_2_5 <= sign_reg_2;
        // 将部分积分成高低位
        a_cos_p1_low <= a_cos_partial_1[19:0];
        a_cos_p1_high <= {7'd0, a_cos_partial_1[26:20]};
        a_cos_p2_low <= a_cos_partial_2[19:0];
        a_cos_p2_high <= {7'd0, a_cos_partial_2[26:20]};
        b_div_p1_low <= b_div_partial_1[22:0];
        b_div_p1_high <= {7'd0, b_div_partial_1[29:23]};
        b_div_p2_low <= b_div_partial_2[22:0];
        b_div_p2_high <= {7'd0, b_div_partial_2[29:23]};
    end
end

//第4级：计算完整的乘法结果
reg [26:0] a_cos;
reg [29:0] b_div;
reg sign_reg_3;

always@(posedge clk) begin
    if(!rst_n) begin
        a_cos <= 27'd0;
        b_div <= 30'd0;
        sign_reg_3 <= 1'b0;
    end else begin
        sign_reg_3 <= sign_reg_2_5;
        // 合并部分积得到完整结果
        a_cos <= a_cos_partial_1 + (a_cos_partial_2 << 8);
        b_div <= b_div_partial_1 + (b_div_partial_2 << 9);
    end
end

//第4.5级：新增流水线级 - 复制信号以减少扇出
reg [26:0] a_cos_copy1, a_cos_copy2, a_cos_copy3, a_cos_copy4, a_cos_copy5;
reg [29:0] b_div_copy1, b_div_copy2, b_div_copy3, b_div_copy4, b_div_copy5;
reg sign_reg_3_5;

always@(posedge clk) begin
    if(!rst_n) begin
        a_cos_copy1 <= 27'd0;
        a_cos_copy2 <= 27'd0;
        a_cos_copy3 <= 27'd0;
        a_cos_copy4 <= 27'd0;
        a_cos_copy5 <= 27'd0;
        b_div_copy1 <= 30'd0;
        b_div_copy2 <= 30'd0;
        b_div_copy3 <= 30'd0;
        b_div_copy4 <= 30'd0;
        b_div_copy5 <= 30'd0;
        sign_reg_3_5 <= 1'b0;
    end else begin
        sign_reg_3_5 <= sign_reg_3;
        // 复制信号，每个副本只驱动5个乘法器
        a_cos_copy1 <= a_cos;
        a_cos_copy2 <= a_cos;
        a_cos_copy3 <= a_cos;
        a_cos_copy4 <= a_cos;
        a_cos_copy5 <= a_cos;
        b_div_copy1 <= b_div;
        b_div_copy2 <= b_div;
        b_div_copy3 <= b_div;
        b_div_copy4 <= b_div;
        b_div_copy5 <= b_div;
    end
end

//第5级：进一步分解乘法，减少每个乘法器的位宽
// 将27x30位乘法分解为更小的乘法器（6位x6位）
reg [11:0] mp_1_1, mp_1_2, mp_1_3, mp_1_4, mp_1_5;
reg [11:0] mp_2_1, mp_2_2, mp_2_3, mp_2_4, mp_2_5;
reg [11:0] mp_3_1, mp_3_2, mp_3_3, mp_3_4, mp_3_5;
reg [11:0] mp_4_1, mp_4_2, mp_4_3, mp_4_4, mp_4_5;
reg [11:0] mp_5_1, mp_5_2, mp_5_3, mp_5_4, mp_5_5;
reg sign_reg_4;

always@(posedge clk) begin
    if(!rst_n) begin
        mp_1_1 <= 12'd0; mp_1_2 <= 12'd0; mp_1_3 <= 12'd0; mp_1_4 <= 12'd0; mp_1_5 <= 12'd0;
        mp_2_1 <= 12'd0; mp_2_2 <= 12'd0; mp_2_3 <= 12'd0; mp_2_4 <= 12'd0; mp_2_5 <= 12'd0;
        mp_3_1 <= 12'd0; mp_3_2 <= 12'd0; mp_3_3 <= 12'd0; mp_3_4 <= 12'd0; mp_3_5 <= 12'd0;
        mp_4_1 <= 12'd0; mp_4_2 <= 12'd0; mp_4_3 <= 12'd0; mp_4_4 <= 12'd0; mp_4_5 <= 12'd0;
        mp_5_1 <= 12'd0; mp_5_2 <= 12'd0; mp_5_3 <= 12'd0; mp_5_4 <= 12'd0; mp_5_5 <= 12'd0;
        sign_reg_4 <= 1'b0;
    end else begin
        sign_reg_4 <= sign_reg_3_5;
        // 使用不同的副本来减少扇出
        // 第1行使用copy1
        mp_1_1 <= a_cos_copy1[5:0]   * b_div_copy1[5:0];
        mp_1_2 <= a_cos_copy1[5:0]   * b_div_copy1[11:6];
        mp_1_3 <= a_cos_copy1[5:0]   * b_div_copy1[17:12];
        mp_1_4 <= a_cos_copy1[5:0]   * b_div_copy1[23:18];
        mp_1_5 <= a_cos_copy1[5:0]   * b_div_copy1[29:24];
        
        // 第2行使用copy2
        mp_2_1 <= a_cos_copy2[11:6]  * b_div_copy2[5:0];
        mp_2_2 <= a_cos_copy2[11:6]  * b_div_copy2[11:6];
        mp_2_3 <= a_cos_copy2[11:6]  * b_div_copy2[17:12];
        mp_2_4 <= a_cos_copy2[11:6]  * b_div_copy2[23:18];
        mp_2_5 <= a_cos_copy2[11:6]  * b_div_copy2[29:24];
        
        // 第3行使用copy3
        mp_3_1 <= a_cos_copy3[17:12] * b_div_copy3[5:0];
        mp_3_2 <= a_cos_copy3[17:12] * b_div_copy3[11:6];
        mp_3_3 <= a_cos_copy3[17:12] * b_div_copy3[17:12];
        mp_3_4 <= a_cos_copy3[17:12] * b_div_copy3[23:18];
        mp_3_5 <= a_cos_copy3[17:12] * b_div_copy3[29:24];
        
        // 第4行使用copy4
        mp_4_1 <= a_cos_copy4[23:18] * b_div_copy4[5:0];
        mp_4_2 <= a_cos_copy4[23:18] * b_div_copy4[11:6];
        mp_4_3 <= a_cos_copy4[23:18] * b_div_copy4[17:12];
        mp_4_4 <= a_cos_copy4[23:18] * b_div_copy4[23:18];
        mp_4_5 <= a_cos_copy4[23:18] * b_div_copy4[29:24];
        
        // 第5行使用copy5
        mp_5_1 <= {3'b0, a_cos_copy5[26:24]} * b_div_copy5[5:0];
        mp_5_2 <= {3'b0, a_cos_copy5[26:24]} * b_div_copy5[11:6];
        mp_5_3 <= {3'b0, a_cos_copy5[26:24]} * b_div_copy5[17:12];
        mp_5_4 <= {3'b0, a_cos_copy5[26:24]} * b_div_copy5[23:18];
        mp_5_5 <= {3'b0, a_cos_copy5[26:24]} * b_div_copy5[29:24];
    end
end

//第5.5级：新增流水线级 - 第一级部分积累加
reg [29:0] sum_p1, sum_p2, sum_p3, sum_p4, sum_p5;
reg sign_reg_4_5;

always@(posedge clk) begin
    if(!rst_n) begin
        sum_p1 <= 30'd0;
        sum_p2 <= 30'd0;
        sum_p3 <= 30'd0;
        sum_p4 <= 30'd0;
        sum_p5 <= 30'd0;
        sign_reg_4_5 <= 1'b0;
    end else begin
        sign_reg_4_5 <= sign_reg_4;
        // 5个并行加法器，每个处理一行
        sum_p1 <= mp_1_1 + {mp_1_2, 6'b0} + {mp_1_3, 12'b0} + {mp_1_4, 18'b0} + {mp_1_5, 24'b0};
        sum_p2 <= mp_2_1 + {mp_2_2, 6'b0} + {mp_2_3, 12'b0} + {mp_2_4, 18'b0} + {mp_2_5, 24'b0};
        sum_p3 <= mp_3_1 + {mp_3_2, 6'b0} + {mp_3_3, 12'b0} + {mp_3_4, 18'b0} + {mp_3_5, 24'b0};
        sum_p4 <= mp_4_1 + {mp_4_2, 6'b0} + {mp_4_3, 12'b0} + {mp_4_4, 18'b0} + {mp_4_5, 24'b0};
        sum_p5 <= mp_5_1 + {mp_5_2, 6'b0} + {mp_5_3, 12'b0} + {mp_5_4, 18'b0} + {mp_5_5, 24'b0};
    end
end

//第6级：第二级部分积累加
reg [56:0] result_partial_1;
reg [56:0] result_partial_2;
reg sign_reg_5;

always@(posedge clk) begin
    if(!rst_n) begin
        result_partial_1 <= 57'd0;
        result_partial_2 <= 57'd0;
        sign_reg_5 <= 1'b0;
    end else begin
        sign_reg_5 <= sign_reg_4_5;
        // 合并5个部分积，按照正确的位移权重
        result_partial_1 <= {27'd0, sum_p1} + {21'd0, sum_p2, 6'b0};
        result_partial_2 <= {15'd0, sum_p3, 12'b0} + {9'd0, sum_p4, 18'b0} + {3'd0, sum_p5, 24'b0};
    end
end

//第7级：最终结果计算
reg [56:0] result;
reg sign_reg_6;

always@(posedge clk) begin
    if(!rst_n) begin
        result <= 57'd0;
        sign_reg_6 <= 1'b0;
    end else begin
        sign_reg_6 <= sign_reg_5;
        result <= result_partial_1 + result_partial_2;
    end
end

//第8级：优化的输出级 - 使用寄存器输出减少组合逻辑延时
reg [12:0] result_rounded;
reg sign_reg_7;

always@(posedge clk) begin
    if(!rst_n) begin
        result_rounded <= 13'd0;
        sign_reg_7 <= 1'b0;
    end else begin
        sign_reg_7 <= sign_reg_6;
        // 四舍五入
        result_rounded <= result[45:33] + result[32];
    end
end

//第9级：最终输出寄存器
always@(posedge clk) begin
    if(!rst_n) begin
        y <= 13'd0;
    end else begin
        // 符号位处理：结果已经是绝对值，只需根据符号位决定正负
        y <= sign_reg_7 ? -{1'b0, result_rounded[11:0]} : {1'b0, result_rounded[11:0]};
    end
end

endmodule