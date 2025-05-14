module function_gen(
	input [11:0] a,
	input [11:0] b,
	input [11:0] c,
	input e,
	input clk,
	output wire signed [12:0] y,
	output done_1
);

parameter WIDTH = 38;
parameter FBITS = 12;
parameter Q = 12;
parameter N = 13;

reg rst = 1'b0;
reg [1:0] cnt_rst = 2'b0;
reg [11:0] d_reg = 12'd0;
reg [4:0] d_cnt = 5'd0;
reg d_ready = 1'b0;
reg  valid;
reg dbz;
reg done;

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
reg [24:0] a_plus_d = 25'd0;
always@(posedge clk) begin
	if(d_ready) begin
		a_reg <= a;
		b_reg <= b;
		c_reg <= c;
		mult_ab <= a * b;
		a_plus_d <= (a + d_reg) << 12;
	end
end


reg signed [12:0] cos_val;
cos_lut_digit cos_table(
	.addr(c_reg),
	.cos_out(cos_val)
);


reg signed [37:0] numerator = 38'd0;
reg signed [37:0] denominator = 38'd0;
always@(posedge clk) begin
	if(d_ready) begin
		numerator <= {2'b00, mult_ab, 12'b0};
		denominator <= {1'b0, a_plus_d, 12'b0};
	end
end

always@(posedge clk) begin
	if(cnt_rst >= 2'b11)
		cnt_rst <= cnt_rst;
	else if(cnt_rst == 2'b10) begin
		rst <= ~rst;
		cnt_rst <= cnt_rst + 1'b1;
	end else if(cnt_rst == 2'b01) begin
		rst <= ~rst;
		cnt_rst <= cnt_rst + 1'b1;
	end else 
		cnt_rst <= cnt_rst + 1'b1;
end

reg signed [37:0] div_result;
reg signed [12:0] val_div;
div #(
	.WIDTH(WIDTH),
	.FBITS(FBITS)
) u_div(
	.clk(clk),
	.rst(rst),
	.start(d_ready),
	.done(done),
	.valid(valid),
	.dbz(dbz),
	.a(numerator),
	.b(denominator),
	.div_val(div_result),
	.val_div(val_div)
);

reg mult_done;
mult_digit #(
	.Q(Q),
	.N(N)
) u_mult_digit(
	.i_clk(clk),
	.i_start(done),
	.i_multiplicand(val_div),
	.i_multiplier(cos_val),
	.o_result_out(y),
	.reg_done(mult_done)
);
	

assign done_1 = mult_done;

endmodule
