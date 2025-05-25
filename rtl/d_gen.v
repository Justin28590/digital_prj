module d_gen(
    input   clk 	,
    input   e   	,
	input 	rst_n	,
    output reg [11:0] d,
	output reg d_ready
);

reg [3:0] d_cnt;

always@(posedge clk) begin
	if(rst_n == 1'b0) begin
		d_cnt <= 4'd0;
		d_ready <= 1'd0;
		d <= 12'd0;
	end
	else begin 
		if(!d_ready)
			d <= {d[10:0],e};
		else 
			d <= d;
		if(d_cnt > 4'd10) begin
			d_ready <= 1'b1;
			d_cnt <= 4'd0;
		end else begin
			d_cnt <= d_cnt + 4'd1;
		end
	end
end

endmodule
