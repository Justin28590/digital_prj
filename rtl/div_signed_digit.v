module div_signed_digit #(
    parameter WIDTH = 8,
    parameter FBITS = 4
)(
    input clk,
    input rst,
    input start,
    output reg busy,
    output reg done,
    output reg valid,
    output reg dbz,
    output reg ovf,
    input signed [WIDTH-1:0] a,
    input signed [WIDTH-1:0] b,
    output reg signed [WIDTH-1:0] val
);

localparam WIDTHU = WIDTH - 1;
localparam FBITSW = (FBITS == 0) ? 1 : FBITS;
localparam ITER = WIDTHU + FBITS;
localparam SMALLEST = {1'b1, {WIDTHU{1'b0}}}; //最小的负数

reg a_sig, b_sig, sig_diff; //a,b符号位
reg [WIDTHU-1:0] au, bu; //a,b的unsigned绝对值
reg [WIDTHU-1:0] quo, quo_next;
reg [WIDTHU:0] acc, acc_next;
reg [$clog2(ITER):0] i; //分配的是足够容纳ITER的最小位宽+1位，例如ITER=16 时，i是[4:0]，可计数到 31，完全足够；

always @(*) begin //这里的实现逻辑完全与之前一致
    if (acc >= {1'b0, bu}) begin
        acc_next = acc - bu;
        {acc_next, quo_next} = {acc_next[WIDTHU-1:0], quo, 1'b1};
    end else begin
        {acc_next, quo_next} = {acc, quo} << 1;
    end
end

// 状态机定义
localparam IDLE = 0, INIT = 1, CALC = 2,  SIGN = 3;
reg [2:0] state;

always @(posedge clk) begin
    done <= 0;
    case (state)
        IDLE: begin
            if (start) begin
                valid <= 0;
                if (b == 0) begin
                    state <= IDLE; //计算完成，回到空闲状态
                    busy <= 0;
                    done <= 1;
                    dbz <= 1;
                    ovf <= 0;
                end else if (a == SMALLEST || b == SMALLEST) begin //最小负数取补码时会溢出
                    state <= IDLE;
                    busy <= 0;
                    done <= 1;
                    dbz <= 0;
                    ovf <= 1;
                end else begin
                    au <= (a[WIDTH-1]) ? -a[WIDTHU-1:0] : a[WIDTHU-1:0]; //-直接取补
                    bu <= (b[WIDTH-1]) ? -b[WIDTHU-1:0] : b[WIDTHU-1:0];
                    sig_diff <= a[WIDTH-1] ^ b[WIDTH-1];
                    busy <= 1;
                    dbz <= 0;
                    ovf <= 0;
                    state <= INIT;
                end
            end
        end
        INIT: begin
            state <= CALC;
            i <= 0;
            {acc, quo} <= {{WIDTHU{1'b0}}, au, 1'b0};
        end
        CALC: begin
            if (i == WIDTHU-1 && quo_next[WIDTHU-1:WIDTHU-FBITSW] != 0) begin //这里如果不为0，继续左移会丢失掉1因此说明是溢出的
                state <= IDLE;
                busy <= 0;
                done <= 1;
                ovf <= 1;
            end else if (i == ITER) begin
                state <= SIGN;
            end else begin
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end
        SIGN: begin
            state <= IDLE;
            busy <= 0;
            done <= 1;
            valid <= 1;
            val <= (quo != 0 && sig_diff) ? {1'b1, -quo} : {1'b0, quo};
        end
    endcase

    if (rst) begin
        state <= IDLE;
        busy <= 0;
        done <= 0;
        valid <= 0;
        dbz <= 0;
        ovf <= 0;
        val <= 0;
    end
end

endmodule
