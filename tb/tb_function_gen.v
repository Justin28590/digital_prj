module tb_function_gen;

reg [11:0] a, b, c;
reg e;
reg clk;
wire signed [12:0] y;
wire done;

// 实例化 DUT
function_gen dut (
    .a(a),
    .b(b),
    .c(c),
    .e(e),
    .clk(clk),
    .y(y),
		.done_1(done)
);

// 时钟生成
initial clk = 0;
always #2500 clk=~clk;

initial begin
    a = 0; b = 0; c = 0; e = 0;
    #2000
		a				=	12'd10;
		b				= 12'd1000;
		c				= 12'd1662;
		gen_e(12'd1024);
		wait(done);	
		gen_e(12'd2048);
		$finish;
end

integer i;
task gen_e(input [11:0] d_input);
	for(i=11;i>=0;i=i-1) begin 
		@(posedge clk)
			e = d_input[i];
	end
endtask

initial begin
	$fsdbDumpfile("tb_function_gen.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA();
end

endmodule
