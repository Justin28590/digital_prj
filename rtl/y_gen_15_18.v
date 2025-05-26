module y_gen(    
    input rst_n,       
    input [11:0] a,
    input [11:0] b,
    input [11:0] c,
    input e,
    input clk,
    output wire signed [12:0] y
);

//第0级：初始化，寄存变量值，每个时钟周期都可以处理一组新数据,计算a+d的值
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

//第1级：cos查表,取绝对值，div查表，同时继续传递a,b的值后面乘法要用
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

//第2级：保存符号，计算a*cos,b*div
reg sign_reg;
reg [14:0] cos_abs;
reg  [11:0] a_reg_3;
reg  [11:0] b_reg_3;
reg  [17:0] div_reg_2;
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

// 分段乘法：将15位数分成3个5位段
reg [8:0] a1cos1, a2cos1, a3cos1;
reg [8:0] a1cos2, a2cos2, a3cos2;
reg [8:0] a1cos3, a2cos3, a3cos3;

// 将18位div分成3*6
reg [9:0] b1d1, b2d1, b3d1;
reg [9:0] b1d2, b2d2, b3d2;
reg [9:0] b1d3, b2d3, b3d3;

always@(posedge clk) begin
    if(!rst_n) begin
        a1cos1 <= 9'd0;
        a2cos1 <= 9'd0;
        a3cos1 <= 9'd0;
        a1cos2 <= 9'd0;
        a2cos2 <= 9'd0;
        a3cos2 <= 9'd0;
        a1cos3 <= 9'd0;
        a2cos3 <= 9'd0;
        a3cos3 <= 9'd0;

        b1d1 <= 10'd0;
        b2d1 <= 10'd0;
        b3d1 <= 10'd0;
        b1d2 <= 10'd0;
        b2d2 <= 10'd0;
        b3d2 <= 10'd0;
        b1d3 <= 10'd0;
        b2d3 <= 10'd0;
        b3d3 <= 10'd0; 
    end else begin
        a1cos1 <= a_reg_3[3:0] * cos_abs[4:0];
        a2cos1 <= a_reg_3[7:4] * cos_abs[4:0];
        a3cos1 <= a_reg_3[11:8]* cos_abs[4:0];
        a1cos2 <= a_reg_3[3:0] * cos_abs[9:5];
        a2cos2 <= a_reg_3[7:4] * cos_abs[9:5];
        a3cos2 <= a_reg_3[11:8]* cos_abs[9:5];
        a1cos3 <= a_reg_3[3:0] * cos_abs[14:10];
        a2cos3 <= a_reg_3[7:4] * cos_abs[14:10];
        a3cos3 <= a_reg_3[11:8]* cos_abs[14:10];

        b1d1 <= b_reg_3[3:0] * div_reg_2[5:0];
        b2d1 <= b_reg_3[7:4] * div_reg_2[5:0];
        b3d1 <= b_reg_3[11:8]* div_reg_2[5:0];
        b1d2 <= b_reg_3[3:0] * div_reg_2[11:6];
        b2d2 <= b_reg_3[7:4] * div_reg_2[11:6];
        b3d2 <= b_reg_3[11:8]* div_reg_2[11:6];
        b1d3 <= b_reg_3[3:0] * div_reg_2[17:12];
        b2d3 <= b_reg_3[7:4] * div_reg_2[17:12];
        b3d3 <= b_reg_3[11:8]* div_reg_2[17:12];
    end
end

//第3级：将部分积进行合并（修正移位权重）
reg sign_reg_2;
reg [26:0] a_cos;
reg [29:0] b_div;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_2 <= 1'b0;
        a_cos <= 27'd0;
        b_div <= 30'd0;
    end else begin
        sign_reg_2 <= sign_reg;
        // 修正a*cos的部分积合并
        a_cos <= a1cos1 + 
                {a2cos1, 4'b0} + 
                {a3cos1, 8'b0} + 
                {a1cos2, 5'b0} + 
                {a2cos2, 9'b0} + 
                {a3cos2, 13'b0} + 
                {a1cos3, 10'b0} + 
                {a2cos3, 14'b0} + 
                {a3cos3, 18'b0};
        // 修正b*div的部分积合并
        b_div <= b1d1 + 
                {b2d1, 4'b0} + 
                {b3d1, 8'b0} + 
                {b1d2, 6'b0} + 
                {b2d2, 10'b0} + 
                {b3d2, 14'b0} + 
                {b1d3, 12'b0} + 
                {b2d3, 16'b0} + 
                {b3d3, 20'b0}; 
    end
end

reg sign_reg_3;
reg [26:0] a_cos_reg;
reg [29:0] b_div_reg;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_3 <= 1'b0;
        a_cos_reg <= 27'd0;
        b_div_reg <= 30'd0;
    end else begin
        sign_reg_3 <= sign_reg_2;
        a_cos_reg <= a_cos;
        b_div_reg <= b_div;
    end
end

//第4级：将a_cos和b_div以部分积相乘
// 将27位a_cos分成3*7+6，30位b_div分成3*7+9
reg sign_reg_4;
reg [13:0] x1y1, x2y1, x3y1;
reg [13:0] x1y2, x2y2, x3y2;
reg [13:0] x1y3, x2y3, x3y3;
reg [15:0] x1y4, x2y4, x3y4;
reg [12:0] x4y1, x4y2, x4y3;
reg [14:0] x4y4;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_4 <= 1'b0;
        x1y1 <= 14'd0;
        x2y1 <= 14'd0;
        x3y1 <= 14'd0;
        x1y2 <= 14'd0;
        x2y2 <= 14'd0;
        x3y2 <= 14'd0;
        x1y3 <= 14'd0;
        x2y3 <= 14'd0;
        x3y3 <= 14'd0;
        x1y4 <= 16'd0;
        x2y4 <= 16'd0;
        x3y4 <= 16'd0;
        x4y1 <= 13'd0;
        x4y2 <= 13'd0;
        x4y3 <= 13'd0;
        x4y4 <= 15'd0; 
    end else begin
        sign_reg_4 <= sign_reg_3;
        x1y1 <= a_cos_reg[6:0]   * b_div_reg[6:0];
        x2y1 <= a_cos_reg[13:7]  * b_div_reg[6:0];
        x3y1 <= a_cos_reg[20:14] * b_div_reg[6:0];
        x4y1 <= a_cos_reg[26:21] * b_div_reg[6:0];
        x1y2 <= a_cos_reg[6:0]   * b_div_reg[13:7];
        x2y2 <= a_cos_reg[13:7]  * b_div_reg[13:7];
        x3y2 <= a_cos_reg[20:14] * b_div_reg[13:7];
        x4y2 <= a_cos_reg[26:21] * b_div_reg[13:7]; 
        x1y3 <= a_cos_reg[6:0]   * b_div_reg[20:14];
        x2y3 <= a_cos_reg[13:7]  * b_div_reg[20:14];
        x3y3 <= a_cos_reg[20:14] * b_div_reg[20:14];
        x4y3 <= a_cos_reg[26:21] * b_div_reg[20:14];
        x1y4 <= a_cos_reg[6:0]   * b_div_reg[29:21];
        x2y4 <= a_cos_reg[13:7]  * b_div_reg[29:21];
        x3y4 <= a_cos_reg[20:14] * b_div_reg[29:21];
        x4y4 <= a_cos_reg[26:21] * b_div_reg[29:21];
    end
end

//第5级：合并部分积（修正移位权重）
reg sign_reg_5;
reg [56:0] result;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_5 <= 1'b0;
        result <= 57'd0;
    end else begin
        sign_reg_5 <= sign_reg_4;
        result <= x1y1 + 
                 {x2y1, 7'b0} + 
                 {x3y1, 14'b0} + 
                 {x4y1, 20'b0} + 
                 {x1y2, 7'b0} + 
                 {x2y2, 14'b0} + 
                 {x3y2, 21'b0} + 
                 {x4y2, 28'b0} + 
                 {x1y3, 14'b0} + 
                 {x2y3, 21'b0} + 
                 {x3y3, 28'b0} + 
                 {x4y3, 35'b0} + 
                 {x1y4, 21'b0} + 
                 {x2y4, 28'b0} + 
                 {x3y4, 35'b0} + 
                 {x4y4, 42'b0};
    end
end

//第6级：右移并截取结果
// 考虑到精度要求，我们需要更仔细地处理截位
wire [12:0] result_rounded;
reg sign_reg_6;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_6 <= 1'b0;
    end else begin
        sign_reg_6 <= sign_reg_5;
    end
end

// 改进的四舍五入处理
// cos是15位精度
// div_lut输出是18位，实际右移33位
assign result_rounded = result[32] ? 
                       (result[45:33] + 1'b1) : 
                       result[45:33];

// 限制输出范围在12位以内
wire [12:0] result_saturated;
assign result_saturated = (result_rounded > 13'd4095) ? 13'd4095 : result_rounded;

assign y = sign_reg_6 ? {1'b1, -result_saturated[11:0]} : {1'b0, result_saturated[11:0]};

endmodule