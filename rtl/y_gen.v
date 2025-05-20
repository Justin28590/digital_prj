module y_gen(           
    input [11:0] a,
	input [11:0] b,
	input [11:0] c,
	input e,
	input clk,
	output wire signed [12:0] y
);

//增加rst复位信号消除不确定初始态
reg rst_n;
always@(posedge clk) begin
	if(a != 12'd0)
		rst_n <= 1'b1;
	else 
		rst_n <= 1'b0;
end

//第0级：初始化，寄存变量值，每个时钟周期都可以处理一组新数据,计算a+d的值
reg [11:0] a_reg, b_reg, c_reg;
reg [12:0] apd_reg;
wire [11:0] d;  //例化的输出信号必须连接wire
d_gen u_d_gen(
    .clk(clk),
    .e(e),
	.rst_n(rst_n),
    .d(d)
);

always@(posedge clk) begin 
    a_reg <= a;
    b_reg <= b;
    c_reg <= c;
    apd_reg <= a + d;
end

//第1级：cos查表,取绝对值，div查表，同时继续传递a,b的值后面乘法要用
wire [12:0] cos_wire;
reg  [11:0] a_reg_2;
reg  [11:0] b_reg_2;
cos_lut u_cos_lut(
    .addr(c_reg),
    .cos_out(cos_wire)
);
wire [14:0] div_wire;        //div 12位精度不太够->增大到15位
reg  [14:0] div_reg;
div_lut u_div_lut(
    .apd(apd_reg),
    .div_val(div_wire)
);
always@(posedge clk) begin
   a_reg_2 <= a_reg;
   b_reg_2 <= b_reg;
   div_reg <= div_wire;
end

//第2级：保存符号，计算a*cos,b*div:cos12位分成4*3，div15位分成5*3，a和b各12位分成4*3
reg sign_reg;
reg [11:0] cos_abs;
reg [7:0] a1cos1, a2cos1, a3cos1;
reg [7:0] a1cos2, a2cos2, a3cos2;
reg [7:0] a1cos3, a2cos3, a3cos3;

reg [8:0] b1d1, b1d2, b1d3;
reg [8:0] b2d1, b2d2, b2d3;
reg [8:0] b3d1, b3d2, b3d3;
always@(posedge clk) begin
    sign_reg <= cos_wire[12];
    cos_abs <= (cos_wire[12]) ? -cos_wire[11:0] : cos_wire[11:0];
    a1cos1 <= a_reg_2[3:0] * cos_abs[3:0];
    a2cos1 <= a_reg_2[7:4] * cos_abs[3:0];
    a3cos1 <= a_reg_2[11:8]* cos_abs[3:0];
    a1cos2 <= a_reg_2[3:0] * cos_abs[7:4];
    a2cos2 <= a_reg_2[7:4] * cos_abs[7:4];
    a3cos2 <= a_reg_2[11:8]* cos_abs[7:4];
    a1cos3 <= a_reg_2[3:0] * cos_abs[11:8];
    a2cos3 <= a_reg_2[7:4] * cos_abs[11:8];
    a3cos3 <= a_reg_2[11:8]* cos_abs[11:8];

    b1d1 <= b_reg_2[3:0] * div_reg[4:0];
    b2d1 <= b_reg_2[7:4] * div_reg[4:0];
    b3d1 <= b_reg_2[11:8]* div_reg[4:0];
    b1d2 <= b_reg_2[3:0] * div_reg[9:5];
    b2d2 <= b_reg_2[7:4] * div_reg[9:5];
    b3d2 <= b_reg_2[11:8]* div_reg[9:5];
    b1d3 <= b_reg_2[3:0] * div_reg[14:10];
    b2d3 <= b_reg_2[7:4] * div_reg[14:10];
    b3d3 <= b_reg_2[11:8]* div_reg[14:10];
end

//第3级：将部分积进行合并
reg sign_reg_2;
reg [23:0] a_cos;
reg [26:0] b_div;
always@(posedge clk) begin
   sign_reg_2 <= sign_reg;
   a_cos <= a1cos1 + {a2cos1, 4'b0} + {a3cos1, 8'b0} + {a1cos2, 4'b0} + {a2cos2, 8'b0} + {a3cos2, 12'b0} + {a1cos3, 8'b0} + {a2cos3, 12'b0} + {a3cos3, 16'b0};
   b_div <= b1d1 + {b2d1,4'b0} + {b3d1,8'b0} + {b1d2,5'b0} + {b2d2,9'b0} + {b3d2,13'b0} + {b1d3,10'b0} + {b2d3,14'b0} + {b3d3,18'b0}; 
end

//第4级：将a_cos和b_div以部分积相乘,a_cos24位分成6*4，b_div27位分成7*3+6
reg sign_reg_3;
reg [12:0] x1y1, x2y1, x3y1, x4y1;
reg [12:0] x1y2, x2y2, x3y2, x4y2;
reg [12:0] x1y3, x2y3, x3y3, x4y3;
reg [11:0] x1y4, x2y4, x3y4, x4y4;
always@(posedge clk) begin
    sign_reg_3 <= sign_reg_2;
    x1y1 <= a_cos[5:0]   * b_div[6:0];
    x2y1 <= a_cos[11:6]  * b_div[6:0];
    x3y1 <= a_cos[17:12] * b_div[6:0];
    x4y1 <= a_cos[23:18] * b_div[6:0];
    x1y2 <= a_cos[5:0]   * b_div[13:7];
    x2y2 <= a_cos[11:6]  * b_div[13:7];
    x3y2 <= a_cos[17:12] * b_div[13:7];
    x4y2 <= a_cos[23:18] * b_div[13:7]; 
    x1y3 <= a_cos[5:0]   * b_div[20:14];
    x2y3 <= a_cos[11:6]  * b_div[20:14];
    x3y3 <= a_cos[17:12] * b_div[20:14];
    x4y3 <= a_cos[23:18] * b_div[20:14];
    x1y4 <= a_cos[5:0]   * b_div[26:21];
    x2y4 <= a_cos[11:6]  * b_div[26:21];
    x3y4 <= a_cos[17:12] * b_div[26:21];
    x4y4 <= a_cos[23:18] * b_div[26:21];
end

//第5级：合并部分积
reg sign_reg_4;
reg [50:0] result;
always@(posedge clk) begin
    sign_reg_4 <= sign_reg_3;
    result <= x1y1+{x2y1,6'b0}+{x3y1,12'b0}+{x4y1,18'b0}+{x1y2,7'b0}+{x2y2,13'b0}+{x3y2,19'b0}+{x4y2,25'b0}+{x1y3+14'b0}+{x2y3,20'b0}+{x3y3,26'b0}+{x4y3,32'b0}+{x1y4,21'b0}+{x2y4,27'b0}+{x3y4,33'b0}+{x4y4,39'b0};
end

//第6级：右移12位，截取12位，合并符号位
wire [11:0] result_cut;
reg sign_reg_5;
always@(posedge clk) begin
    sign_reg_5 <= sign_reg_4;
end
assign result_cut = result[26]?(result[38:27]+1'b1):result[38:27];
assign y = sign_reg_5 ? {1'b1,-result_cut} : {1'b0,result_cut};

endmodule
