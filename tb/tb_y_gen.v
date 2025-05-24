module tb_y_gen;

reg [11:0] a, b, c;
reg e;
reg clk;
reg rst_n;
wire signed [12:0] y;

// 实例化 DUT
y_gen u_y_gen(
    .rst_n(rst_n),
    .a(a),
    .b(b),
    .c(c),
    .e(e),
    .clk(clk),
    .y(y)
);

// 时钟生成
initial clk = 0;
always #25 clk = ~clk;


// 多次在 clk 上升沿改变 a, b, c，e 只输入一次
reg [11:0] a_vals [2:0];
reg [11:0] b_vals [2:0];
reg [11:0] c_vals [2:0];

integer i;
initial begin
    rst_n = 0;
    a = 0;b = 0;c = 0;e = 0;
    #30;
    rst_n = 1;
    a_vals[0] = 12'd10;   b_vals[0] = 12'd1000; c_vals[0] = 12'd2400;
    a_vals[1] = 12'd200;   b_vals[1] = 12'd900;  c_vals[1] = 12'd3200;
    a_vals[2] = 12'd1000;   b_vals[2] = 12'd4095; c_vals[2] = 12'd4095;
    // e 只输入一次
    gen_e(12'd1024);
    // 连续输入 a, b, c（每个在 posedge clk 改变）
    for (i = 0; i < 3; i = i + 1) begin
        @(posedge clk);
        a <= a_vals[i];
        b <= b_vals[i];
        c <= c_vals[i];
	end
    #500;
    $finish;
end

task gen_e(input [11:0] d_input);
    integer j;
    for (j = 11; j >= 0; j = j - 1) begin
        	@(negedge clk)
            e = d_input[j];
    end
endtask

initial begin
    $fsdbDumpfile("tb_y_gen.fsdb");
    $fsdbDumpvars;
    $fsdbDumpMDA();
end

endmodule

