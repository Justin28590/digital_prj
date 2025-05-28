module y_gen(    
    input rst_n,       
    input [11:0] a,
    input [11:0] b,
    input [11:0] c,
    input e,
    input clk,
    output reg [12:0] y
);

//第0级：初始化，寄存变量值
reg [11:0] a_reg, b_reg, c_reg;
reg [12:0] apd_reg;
//reg apd_ready;
wire [11:0] d;
wire d_ready;
reg d_ready_reg;

d_gen u_d_gen(
    .clk(clk),
    .e(e),
    .rst_n(rst_n),
    .d(d),
    .d_ready(d_ready)
);

always@(posedge clk) begin 
    if(!rst_n || !d_ready) begin
        a_reg <= 12'd0;
        b_reg <= 12'd0;
        c_reg <= 12'd0;
        apd_reg <= 13'd0;
        d_ready_reg <= 1'b0;
    end else begin
        a_reg <= a;
        b_reg <= b;
        c_reg <= c;
        apd_reg <= a + d;
        d_ready_reg <= d_ready;
    end
end

//第1级：cos查表和div查表
wire [15:0] cos_wire;
reg  [15:0] cos_reg;
reg  [11:0] a_reg_2;
reg  [11:0] b_reg_2;
cos_lut u_cos_lut(
    .addr(c_reg),
    .d_ready(d_ready_reg),
    .cos_out(cos_wire)
);

wire [3:0]  segment_type;   
wire [6:0] offset;
wire [7:0] idx_out;
apd_idx u_apd_idx(
    .apd(apd_reg),
    .segment_type(segment_type),
    .offset(offset),
    .idx_out(idx_out)
);

reg [3:0] segment_type_reg;
reg [6:0] offset_reg;
reg [7:0] idx_out_reg;
always@(posedge clk) begin
    if(!rst_n) begin
        segment_type_reg <= 4'd0;
        offset_reg <= 7'd0;
        idx_out_reg <= 8'd0;
    end else begin
        segment_type_reg <= segment_type;
        offset_reg <= offset;
        idx_out_reg <= idx_out;
    end
end

wire  [16:0] div_val;   
reg  [16:0] div_reg;
div_lut u_div_lut(
    .segment_type(segment_type_reg),
    .offset(offset_reg),
    .idx_out(idx_out_reg),
    .div_val(div_val)
);

always@(posedge clk) begin
    if(!rst_n || !d_ready) begin
        a_reg_2 <= 12'd0;
        b_reg_2 <= 12'd0;
        div_reg <= 17'd0;
        cos_reg <= 16'd0;
    end else begin
        a_reg_2 <= a_reg;
        b_reg_2 <= b_reg;
        div_reg <= div_val;
        cos_reg <= cos_wire;
    end
end

//第2级：提取符号和绝对值
reg sign_reg;
reg [14:0] cos_abs;
reg [11:0] a_reg_3;
reg [11:0] b_reg_3;

always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg <= 1'b0;
        cos_abs <= 15'd0;
        a_reg_3 <= 12'd0;
        b_reg_3 <= 12'd0;
    end else begin
        sign_reg <= cos_reg[15];
        cos_abs <= (cos_reg[15]) ? -cos_reg[14:0] : cos_reg[14:0];
        a_reg_3 <= a_reg_2;
        b_reg_3 <= b_reg_2;
    end
end


//cos:15位，div:17位，a,b：12位，a_cos:4+5=9位，b_div:4+6=10位
//减少分段，不然的话加分器太多延迟太高
reg sign_reg_1;
reg [12:0] a1cos1, a2cos1;
reg [13:0] a1cos2, a2cos2;

reg [11:0] b1d1, b2d1;
reg [11:0] b1d2, b2d2;
reg [10:0] b1d3, b2d3;

always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_1 <= 1'b0;
        a1cos1 <= 13'd0;
        a2cos1 <= 13'd0;
        a1cos2 <= 14'd0;
        a2cos2 <= 14'd0;

        b1d1 <= 12'd0;
        b2d1 <= 12'd0;
        b1d2 <= 12'd0;
        b2d2 <= 12'd0;
        b1d3 <= 11'd0;
        b2d3 <= 11'd0;
    end else begin
        sign_reg_1 <= sign_reg;
        a1cos1 <= a_reg_3[5:0] * cos_abs[6:0];
        a2cos1 <= a_reg_3[11:6] * cos_abs[6:0];
        a1cos2 <= a_reg_3[5:0] * cos_abs[14:7];
        a2cos2 <= a_reg_3[11:6] * cos_abs[14:7];

        b1d1 <= b_reg_3[5:0] * div_reg[5:0];
        b2d1 <= b_reg_3[11:6] * div_reg[5:0];
        b1d2 <= b_reg_3[5:0] * div_reg[11:6];
        b2d2 <= b_reg_3[11:6] * div_reg[11:6];
        b1d3 <= b_reg_3[5:0] * div_reg[16:12];
        b2d3 <= b_reg_3[11:6] * div_reg[16:12];
    end
end

reg sign_reg_2;
reg [26:0] a_cos;
reg [28:0] b_div;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_2 <= 1'b0;
        a_cos <= 27'd0;
        b_div <= 30'd0;
    end else begin
        sign_reg_2 <= sign_reg_1;
        a_cos <= a1cos1 + {a2cos1,6'b0} + {a1cos2,7'b0} + {a2cos2,13'b0};
        b_div <= b1d1 + {b2d1,6'b0} + {b1d2,6'b0} + {b2d2,12'b0} + {b1d3,12'b0} + {b2d3,18'b0};
    end
end


//第4级：将a_cos和b_div以部分积相乘,a_cos27位分成6*4+3，b_div29位分成4*6+5
reg sign_reg_3;
reg [13:0]  x1y1, x2y1, x3y1;
reg [13:0]  x1y2, x2y2, x3y2;
reg [13:0]  x1y3, x2y3, x3y3;
reg [12:0]  x4y1, x4y2, x4y3;
reg [14:0]  x1y4, x2y4, x3y4;
reg [13:0]  x4y4;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_3 <= 1'b0;
        x1y1 <= 14'd0;
        x2y1 <= 14'd0;
        x3y1 <= 14'd0;
        x4y1 <= 13'd0;
        x1y2 <= 14'd0;
        x2y2 <= 14'd0;
        x3y2 <= 14'd0;
        x4y2 <= 13'd0;
        x1y3 <= 14'd0;
        x2y3 <= 14'd0;
        x3y3 <= 14'd0;
        x4y3 <= 13'd0;
        x1y4 <= 15'd0;
        x2y4 <= 15'd0;
        x3y4 <= 15'd0;
        x4y4 <= 14'd0; 
    end else begin
        sign_reg_3 <= sign_reg_2;
        x1y1 <= a_cos[6:0]   * b_div[6:0];
        x2y1 <= a_cos[13:7]  * b_div[6:0];
        x3y1 <= a_cos[20:14] * b_div[6:0];
        x4y1 <= a_cos[26:21] * b_div[6:0];
        x1y2 <= a_cos[6:0]   * b_div[13:7];
        x2y2 <= a_cos[13:7]  * b_div[13:7];
        x3y2 <= a_cos[20:14] * b_div[13:7];
        x4y2 <= a_cos[26:21] * b_div[13:7];
        x1y3 <= a_cos[6:0]   * b_div[20:14];
        x2y3 <= a_cos[13:7]  * b_div[20:14];
        x3y3 <= a_cos[20:14] * b_div[20:14];
        x4y3 <= a_cos[26:21] * b_div[20:14];
        x1y4 <= a_cos[6:0]   * b_div[28:21];
        x2y4 <= a_cos[13:7]  * b_div[28:21];
        x3y4 <= a_cos[20:14] * b_div[28:21];
        x4y4 <= a_cos[26:21] * b_div[28:21];
    end
end

reg sign_reg_4;
reg [55:0] result1, result2, result3, result4;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_4 <= 1'b0;
        result1 <= 56'd0;
        result2 <= 56'd0;
        result3 <= 56'd0;
        result4 <= 56'd0;
    end else begin
        sign_reg_4 <= sign_reg_3;
        result1 <= x1y1 + {x2y1,7'b0} + {x3y1,14'b0} + {x4y1,21'b0};
        result2 <= {x1y2,7'b0} + {x2y2,14'b0} + {x3y2,21'b0} + {x4y2,28'b0};
        result3 <= {x1y3,14'b0} + {x2y3,21'b0} + {x3y3,28'b0} + {x4y3,35'b0};
        result4 <= {x1y4,21'b0} + {x2y4,28'b0} + {x3y4,35'b0} + {x4y4,42'b0};
    end
end

reg sign_reg_5;
reg [55:0] result;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_5 <= 1'b0;
        result <= 56'd0;
    end else begin
        sign_reg_5 <= sign_reg_4;
        result <= result1 + result2 + result3 + result4;
    end
end
//第6级：右移12位，截取12位，合并符号位
wire [11:0] result_cut;
wire [12:0] result_sign;
//cos:15位，div:17位，右移32位
assign result_cut = result[31]?(result[43:32]+1'b1):result[43:32];
assign result_sign = sign_reg_5 ? {1'b1,-result_cut} : {1'b0,result_cut};

always@(posedge clk) begin
    if(!rst_n) begin
        y <= 13'b0;
    end else begin
        y <= result_sign;
    end
end

endmodule