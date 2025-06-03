module d_gen(
    input   clk 	,
    input   e   	,
		input 	rst_n	,
    output reg [11:0] d
	
);

reg rst_n_reg;
reg e_reg;
always@(posedge clk) begin
	if(!rst_n) begin
		rst_n_reg <= 1'b0;
	end else begin
		rst_n_reg <= rst_n;
	end
end

reg [3:0] d_cnt;
reg d_ready;
always@(posedge clk) begin
	if(!rst_n_reg) begin
		d_cnt <= 4'd0;
		d_ready <= 1'd0;
		d <= 12'd0;
		e_reg <= 1'b0;
	end else begin 
		e_reg <= e;
		if(!d_ready) begin
			d_cnt <= d_cnt + 1'b1;
			d <= {d[10:0],e};
			if(d_cnt > 4'd10) begin
				d_ready <= 1'b1;
				d_cnt <= d_cnt;
			end
		end
	end
end

endmodule
