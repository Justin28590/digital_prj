module binary_search(
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [17:0] value_in,
    output reg found,
    output reg [7:0] idx_out
);

    // 假设 val_base 是 ROM，预初始化在其他文件中
    reg [17:0] val_base [0:189]; // 数据已知从11~184索引开始填入
    initial $readmemh("val_base.hex", val_base); // 或用 assign 初始化

    reg [7:0] left, right, mid;
    reg searching;

    always @(posedge clk) begin
        if (!rst_n) begin
            left <= 8'd0;
            right <= 8'd174;
            found <= 0;
            idx_out <= 0;
            searching <= 0;
        end else if (start) begin
            left <= 8'd0;
            right <= 8'd189;
            found <= 0;
            searching <= 1;
        end else if (searching) begin
            if (left <= right) begin
                mid = (left + right) >> 1;
                if (val_base[mid] == value_in) begin
                    found <= 1;
                    idx_out <= mid;
                    searching <= 0;
                end else if (val_base[mid] < value_in) begin
                    left <= mid + 1;
                end else begin
                    right <= mid - 1;
                end
            end else begin
                searching <= 0;
                found <= 0;
            end
        end
    end

endmodule
