`timescale 1ns / 1ps

module tb_div_signed_digit;

    parameter WIDTH = 40;
    parameter FBITS = 15;
		
		parameter Q=4;
		parameter N=5;

    reg clk, rst, start;
    reg signed [WIDTH-1:0] a, b;
    wire busy, done, valid, dbz, ovf;
    wire signed [WIDTH-1:0] val;
		reg signed [N-1:0] c,d;
		wire signed [N-1:0] mul_result;
		wire mul_complete;
		wire mul_overflow;

    // 实例化被测模块
    div_signed_digit #(
        .WIDTH(WIDTH),
        .FBITS(FBITS)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .busy(busy),
        .done(done),
        .valid(valid),
        .dbz(dbz),
        .ovf(ovf),
        .a(a),
        .b(b),
        .val(val)
    );

		mult_digit #(
			.Q(Q),
			.N(N)
		) u_mult_digit(
			.i_multiplicand(c),
			.i_multiplier(d),
			.i_start(start),
			.i_clk(clk),
			.o_result_out(mul_result),
			.o_complete(mul_complete),
			.o_overflow(mul_overflow)
		);

    // 生成时钟
    always #5 clk = ~clk;

    initial begin
        // 初始化信号
        clk = 0;
        rst = 1;
        start = 0;
        a = 0;
        b = 0;
				c = 0;
				d = 0;

        // 复位
        #10 rst = 0;

        a = -40'sd271900;
        b = 40'd4235264;
				c = 6'b01000;
				d = 6'b01100;
        start = 1;
        #10 start = 0;

        wait(done);
        #10

        $finish;
    end

		initial begin
			$fsdbDumpfile("tb_div_signed_digit.fsdb");
			$fsdbDumpvars;
			$fsdbDumpMDA();
		end		

endmodule


