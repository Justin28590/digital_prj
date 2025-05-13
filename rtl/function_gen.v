module function_gen(
	input [11:0] a,
	input [11:0] b,
	input [11:0] c,
	input e,
	input clk,
	output reg signed [12:0] y
);

reg [11:0] d_reg = 12'd0;
reg [4:0] d_cnt = 5'd0;
reg d_ready = 1'b0;
reg signed [12:0] xiaoshu = -13'sd1024;//fu shu yao zhuan hua zhi jie chu,bu xu yao zhuan hua wei bu ma zai chu
reg signed [15:0] cos = 16'b1100_0000_0000_0000;
reg signed [27:0] ans;
assign ans = xiaoshu * cos;

reg signed [3:0] beichushu = -4'sd3;
reg [2:0] chushu = 3'b110;
reg signed [5:0] shang;
reg [3:0] beichushuzuoyi; 
assign beichushuzuoyi = (beichushu[3]==1'b0)? (beichushu[2:0]<<1):((~beichushu[2:0]+1)<<1); 
assign shang = beichushuzuoyi /$signed({1'b0,chushu});//qu zui gao yi wei zuo wei fuhaowei


always@(posedge clk) begin
	if(!d_ready) begin
		d_reg <= {d_reg[10:0],e};
	end
	if(d_cnt==5'd11) begin
		d_ready <= 1'b1;
		d_cnt <= 1'd0;
	end
	else 
		d_cnt <= d_cnt +1'b1;
end

reg [11:0] a_reg = 12'd0 ,b_reg = 12'd0,c_reg = 12'd0;
reg [23:0] mult_ab = 24'd0;
always@(posedge clk) begin
	if(d_ready) begin
		a_reg <= a;
		b_reg <= b;
		c_reg <= c;
		mult_ab <= a * b;
	end
end


wire signed [15:0] cos_val;
cos_lut cos_table(
	.addr(c_reg),
	.cos_out(cos_val)
);


reg signed [39:0] numerator = 40'sd0;//ren chu yi 2^15
always@(posedge clk) begin
	if(d_ready) begin
		numerator <= $signed({1'b0,mult_ab}) * $signed(cos_val);
	end
end


reg [24:0] denominator = 25'd0;
always@(posedge clk) begin
	if(d_ready) begin
		denominator <= (a_reg + d_reg) << 12;
	end
end

reg signed [63:0] division_result = 64'd0;
always@(posedge clk) begin
	if(d_ready) begin
		if(denominator != 0)
			division_result <= numerator / denominator;
		else 
			division_result <= 95'd0;
	end
end


always@(posedge clk) begin
	if(d_ready) begin
		y <= division_result[25:13];
	end
end

endmodule
