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

//第4级：合并部分积
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
        // 使用预分解的部分积
        a_cos <= a_cos_p1_low + {a_cos_p1_high, 8'b0} + 
                 {a_cos_p2_low, 8'b0} + {a_cos_p2_high, 16'b0};
        b_div <= b_div_p1_low + {b_div_p1_high, 9'b0} + 
                 {b_div_p2_low, 9'b0} + {b_div_p2_high, 18'b0};
    end
end

//第5级：进一步分解乘法，减少每个乘法器的位宽
// 将27x30位乘法分解为更多的小乘法器
reg [18:0] mult_partial_1_1, mult_partial_1_2, mult_partial_1_3;
reg [18:0] mult_partial_2_1, mult_partial_2_2, mult_partial_2_3;
reg [18:0] mult_partial_3_1, mult_partial_3_2, mult_partial_3_3;
reg sign_reg_4;

always@(posedge clk) begin
    if(!rst_n) begin
        mult_partial_1_1 <= 19'd0;
        mult_partial_1_2 <= 19'd0;
        mult_partial_1_3 <= 19'd0;
        mult_partial_2_1 <= 19'd0;
        mult_partial_2_2 <= 19'd0;
        mult_partial_2_3 <= 19'd0;
        mult_partial_3_1 <= 19'd0;
        mult_partial_3_2 <= 19'd0;
        mult_partial_3_3 <= 19'd0;
        sign_reg_4 <= 1'b0;
    end else begin
        sign_reg_4 <= sign_reg_3;
        // 将a_cos分为3段：[8:0], [17:9], [26:18]
        // 将b_div分为3段：[9:0], [19:10], [29:20]
        // 9x10位乘法器
        mult_partial_1_1 <= a_cos[8:0] * b_div[9:0];
        mult_partial_1_2 <= a_cos[8:0] * b_div[19:10];
        mult_partial_1_3 <= a_cos[8:0] * b_div[29:20];
        mult_partial_2_1 <= a_cos[17:9] * b_div[9:0];
        mult_partial_2_2 <= a_cos[17:9] * b_div[19:10];
        mult_partial_2_3 <= a_cos[17:9] * b_div[29:20];
        mult_partial_3_1 <= a_cos[26:18] * b_div[9:0];
        mult_partial_3_2 <= a_cos[26:18] * b_div[19:10];
        mult_partial_3_3 <= a_cos[26:18] * b_div[29:20];
    end
end

//第5.5级：新增流水线级 - 第一级部分积累加
reg [56:0] sum_partial_1;
reg [56:0] sum_partial_2;
reg [56:0] sum_partial_3;
reg sign_reg_4_5;

always@(posedge clk) begin
    if(!rst_n) begin
        sum_partial_1 <= 57'd0;
        sum_partial_2 <= 57'd0;
        sum_partial_3 <= 57'd0;
        sign_reg_4_5 <= 1'b0;
    end else begin
        sign_reg_4_5 <= sign_reg_4;
        // 按照正确的位移权重累加
        // mult_partial_x_y: x表示a_cos段，y表示b_div段
        sum_partial_1 <= mult_partial_1_1;  // [8:0] * [9:0] 
        sum_partial_2 <= {mult_partial_1_2, 10'b0} +      // [8:0] * [19:10] << 10
                        {mult_partial_2_1, 9'b0} +        // [17:9] * [9:0] << 9
                        {mult_partial_1_3, 20'b0};        // [8:0] * [29:20] << 20
        sum_partial_3 <= {mult_partial_2_2, 19'b0} +      // [17:9] * [19:10] << 19
                        {mult_partial_3_1, 18'b0} +       // [26:18] * [9:0] << 18
                        {mult_partial_2_3, 29'b0} +       // [17:9] * [29:20] << 29
                        {mult_partial_3_2, 28'b0} +       // [26:18] * [19:10] << 28
                        {mult_partial_3_3, 38'b0};        // [26:18] * [29:20] << 38
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
        // 合并3个部分积
        result_partial_1 <= sum_partial_1 + sum_partial_2;
        result_partial_2 <= sum_partial_3;
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