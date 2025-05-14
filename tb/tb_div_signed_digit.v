`timescale 1ns / 1ps

module tb_div_signed_digit;

    parameter WIDTH = 6;
    parameter FBITS = 5;
		
		parameter Q=12;
		parameter N=13;

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
			.reg_done(mul_complete),
			.reg_overflow(mul_overflow)
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

        a = 6'b110000;
        b = 6'b011100;
				c = 13'b1001010111001;
				d = 13'b0000000001001;
        start = 1;
        #10 start = 0;

        wait(mul_complete);
        #10

        $finish;
    end

		initial begin
			$fsdbDumpfile("tb_div_signed_digit.fsdb");
			$fsdbDumpvars;
			$fsdbDumpMDA();
		end		

endmodule


