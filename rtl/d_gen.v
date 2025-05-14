module d_gen(
    input   clk ,
    input   e   ,
    output  reg[11:0]   d
);
reg [2:0]   e_dly;

always @(posedge clk) begin 
    e_dly <= {e_dly[1:0],e}; //把异步信号e通过3级移位寄存器e_dly同步到clk时钟域，防止亚稳态
end

always @(posedge e_dly[2]) begin
    d <= {d[10:0],e};
end

endmodule