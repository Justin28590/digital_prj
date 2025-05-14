module d_gen(
    input   clk ,
    input   e   ,
    output  reg [11:0] d
);

reg [3:0] d_cnt = 4'd0;
reg d_ready = 1'b0;
always @(posedge clk) begin
    if(!d_ready) 
	d <= {d[10:0],e};
    if(d_cnt==4'd11) begin
	d_ready <= 1'b1;
	d_cnt <= 1'd0;
    end else 
	d_cnt <= d_cnt +1'b1;
end

endmodule