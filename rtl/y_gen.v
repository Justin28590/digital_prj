module y_gen(
    input [11:0] a,
	input [11:0] b,
	input [11:0] c,
	input e,
	input clk,
	output wire signed [12:0] y
);

//第一级：初始化，寄存变量值，每个时钟周期都可以处理一组新数据
reg [11:0] a_reg, b_reg, c_reg, d_reg;
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
end

//第二级：cos查表，计算a+d的值,同时继续传递a,b的值后面乘法要用
reg [15:0] cos_out;
reg [15:0] cos_reg;
reg [12:0] apd_reg;
reg [11:0] a_reg_2;
reg [11:0] b_reg_2;
cos_lut u_cos_lut(
    .addr(c),
    .cos_out(cos_out)
);
always@(posedge clk) begin
   cos_reg <= cos_out; 
   apd_reg <= a_reg + d_reg;
   a_reg_2 <= a_reg;
   b_reg_2 <= b_reg;
end

//第三级：cos取绝对值，div值查表
reg [14:0] cos_abs;
reg [23:0] div_val;
reg [23:0] div_reg;
div_lut u_div_lut(
    .apd(apd_reg),
    .div_val(div_val)
);
always@(posedge clk) begin
    cos_abs <= (cos_reg[15]) ? -cos_reg[14:0] : cos_reg[14:0]; 
    div_reg <= div_val;
end
endmodule