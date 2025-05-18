module y_gen(
    input [11:0] a,
	input [11:0] b,
	input [11:0] c,
	input e,
	input clk,
	output wire signed [12:0] y
);

//第零级：初始化，寄存变量值，每个时钟周期都可以处理一组新数据,计算a+d的值
reg [11:0] a_reg, b_reg, c_reg, d_reg;
reg  [12:0] apd_reg;
wire [11:0] d;
d_gen u_d_gen(
    .clk(clk),
    .e(e),
    .d(d)
);
always@(posedge clk) begin 
    a_reg <= a;
    b_reg <= b;
    c_reg <= c;
    d_reg <= d;
    apd_reg <= a + d;
end

//第一级：cos查表,取绝对值，div查表，同时继续传递a,b的值后面乘法要用
wire [12:0] cos_out;
reg  [11:0] a_reg_2;
reg  [11:0] b_reg_2;
reg  [11:0] cos_abs;
cos_lut u_cos_lut(
    .addr(c),
    .cos_out(cos_out)
);
wire [23:0] div_reg;
div_lut u_div_lut(
    .apd(apd_reg),
    .div_val(div_reg)
);
always@(posedge clk) begin
   a_reg_2 <= a_reg;
   b_reg_2 <= b_reg;
   cos_abs <= (cos_out[12]) ? -cos_out[11:0] : cos_out[11:0];
end

//第二级：保存符号，计算a*cos,b*div:cos15位分成5*3，div24位分成6*4，a和b各12位分成4*3
reg sign_reg;
reg [8:0] a1cos1, a2cos1, a3cos1;
reg [8:0] a1cos2, a2cos2, a3cos2;
reg [8:0] a1cos3, a2cos3, a3cos3;

reg [9:0] b1d1, b1d2, b1d3, b1d4;
reg [9:0] b2d1, b2d2, b2d3, b2d4;
reg [9:0] b3d1, b3d2, b3d3, b3d4;
always@(posedge clk) begin
    sign_reg <= cos_out[12];
    a1cos1 <= a_reg_2[3:0] * cos_abs[4:0];
    a2cos1 <= a_reg_2[7:4] * cos_abs[4:0];
    a3cos1 <= a_reg_2[11:8]* cos_abs[4:0];
    a1cos2 <= a_reg_2[3:0] * cos_abs[9:5];
    a2cos2 <= a_reg_2[7:4] * cos_abs[9:5];
    a3cos2 <= a_reg_2[11:8]* cos_abs[9:5];
    a1cos3 <= a_reg_2[3:0] * cos_abs[14:10];
    a2cos3 <= a_reg_2[7:4] * cos_abs[14:10];
    a3cos3 <= a_reg_2[11:8]* cos_abs[14:10];

    b1d1 <= b_reg_2[3:0] * div_reg[5:0];
    b1d2 <= b_reg_2[3:0] * div_reg[11:6];
    b1d3 <= b_reg_2[3:0] * div_reg[17:12];
    b1d4 <= b_reg_2[3:0] * div_reg[23:18];
    b2d1 <= b_reg_2[7:4] * div_reg[5:0];
    b2d2 <= b_reg_2[7:4] * div_reg[11:6];
    b2d3 <= b_reg_2[7:4] * div_reg[17:12];
    b2d4 <= b_reg_2[7:4] * div_reg[23:18];
    b3d1 <= b_reg_2[11:8] * div_reg[5:0];
    b3d2 <= b_reg_2[11:8] * div_reg[11:6];
    b3d3 <= b_reg_2[11:8] * div_reg[17:12];
    b3d4 <= b_reg_2[11:8] * div_reg[23:18];
end

//第五级：将部分积进行合并
reg sign_reg_2;
reg [26:0] a_cos;
reg [35:0] b_div;
always@(posedge clk) begin
   sign_reg_2 <= sign_reg;
   a_cos <= a1cos1 + {a2cos1, 4'b0} + {a3cos1, 8'b0} + {a1cos2, 5'b0} + {a2cos2, 9'b0} + {a3cos2, 13'b0} + {a1cos3, 10'b0} + {a2cos3, 14'b0} + {a3cos3, 18'b0};
   b_div <= b1d1 + {b2d1,4'b0} + {b3d1,8'b0} + {b1d2,6'b0} + {b2d2,10'b0} + {b3d2,14'b0} + {b1d3,12'b0} + {b2d3,16'b0} + {b3d3,20'b0} + {b1d4,18'b0} +{b2d4,22'b0} +{b3d4,26'b0}; 
end

//第六级：将a_cos和b_div以部分积相乘,a_cos27位分成3*7+8，b_div36位分成4*7+8
reg sign_reg_3;
reg [13:0] x1y1, x2y1, x3y1;
reg [12:0] x4y1, x4y2, x4y3, x4y4;
reg [13:0] x1y2, x2y2, x3y2;
reg [13:0] x1y3, x2y3, x3y3;
reg [13:0] x1y4, x2y4, x3y4;
reg [14:0] x1y5, x2y5, x3y5;
reg [13:0] x4y5;
always@(posedge clk) begin
    sign_reg_3 <= sign_reg_2;
    x1y1 <= a_cos[6:0]   * b_div[6:0];
    x2y1 <= a_cos[13:7]  * b_div[6:0];
    x3y1 <= a_cos[20:14] * b_div[6:0];
    x4y1 <= a_cos[26:21] * b_div[6:0];
    x1y2 <= a_cos[6:0]   * b_div[13:7];
    x2y2 <= a_cos[13:7]  * b_div[13:7];
    x3y2 <= a_cos[20:14] * b_div[13:7];
    x4y2 <= a_cos[26:21] * b_div[13:7]; 
    x1y3 <= a_cos[6:0]   * b_div[20:14];
    x2y3 <= a_cos[13:7]  * b_div[20:14];
    x3y3 <= a_cos[20:14] * b_div[20:14];
    x4y3 <= a_cos[26:21] * b_div[20:14]; 
    x1y4 <= a_cos[6:0]   * b_div[27:21];
    x2y4 <= a_cos[13:7]  * b_div[27:21];
    x3y4 <= a_cos[20:14] * b_div[27:21];
    x4y4 <= a_cos[26:21] * b_div[27:21]; 
    x1y5 <= a_cos[6:0]   * b_div[35:28];
    x2y5 <= a_cos[13:7]  * b_div[35:28];
    x3y5 <= a_cos[20:14] * b_div[35:28];
    x4y5 <= a_cos[26:21] * b_div[35:28]; 
end

//第七级：合并部分积
reg sign_reg_4;
reg [62:0] result;
always@(posedge clk) begin
    sign_reg_4 <= sign_reg_3;
    result <= x1y1+{x2y1,7'b0}+{x3y1,14'b0}+{x4y1,21'b0}+{x1y2,7'b0}+{x2y2,14'b0}+{x3y2,21'b0}+{x4y2,28'b0}+{x1y3,14'b0}+{x2y3,21'b0}+{x3y3,28'b0}+{x4y3,35'b0}+{x1y4,21'b0}+{x2y4,28'b0}+{x3y4,35'b0}+{x4y4,42'b0}+{x1y5,28'b0}+{x2y5,35'b0}+{x3y5,42'b0}+{x4y5,49'b0};
end

//第八级：右移12位，截取12位，合并符号位
wire [11:0] result_cut;
reg sign_reg_5;
always@(posedge clk) begin
    sign_reg_5 <= sign_reg_4;
end
assign result_cut = result[50:39];
assign y = sign_reg_5 ? {1'b1,-result_cut} : {1'b0,result_cut};
endmodule
