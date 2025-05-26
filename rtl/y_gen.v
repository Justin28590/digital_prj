module y_gen(    
    input rst_n,       
    input [11:0] a,
    input [11:0] b,
    input [11:0] c,
    input e,
    input clk,
    output reg signed [12:0] y
);

//第0级：初始化，寄存变量值
reg [11:0] a_reg, b_reg, c_reg;
reg [12:0] apd_reg;
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

wire [17:0] div_wire;
reg  [17:0] div_reg;
div_lut u_div_lut(
    .apd(apd_reg),
    .d_ready(d_ready_reg),
    .div_val(div_wire)
);

always@(posedge clk) begin
    if(!rst_n || !d_ready) begin
        a_reg_2 <= 12'd0;
        b_reg_2 <= 12'd0;
        div_reg <= 18'd0;
        cos_reg <= 16'd0;
    end else begin
        a_reg_2 <= a_reg;
        b_reg_2 <= b_reg;
        div_reg <= div_wire;
        cos_reg <= cos_wire;
    end
end

//第2级：提取符号和绝对值
reg sign_reg;
reg [14:0] cos_abs;
reg [11:0] a_reg_3;
reg [11:0] b_reg_3;
reg [17:0] div_reg_2;

always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg <= 1'b0;
        cos_abs <= 15'd0;
        a_reg_3 <= 12'd0;
        b_reg_3 <= 12'd0;
        div_reg_2 <= 18'd0;
    end else begin
        sign_reg <= cos_reg[15];
        cos_abs <= (cos_reg[15]) ? -cos_reg[14:0] : cos_reg[14:0];
        a_reg_3 <= a_reg_2;
        b_reg_3 <= b_reg_2;
        div_reg_2 <= div_reg;
    end
end

//cos:15位，div:18位，a,b：12位，a_cos:4+5=9位，b_div:4+6=10位
reg [8:0] a1cos1, a2cos1, a3cos1;
reg [8:0] a1cos2, a2cos2, a3cos2;
reg [8:0] a1cos3, a2cos3, a3cos3;

reg [9:0] b1d1, b1d2, b1d3;
reg [9:0] b2d1, b2d2, b2d3;
reg [9:0] b3d1, b3d2, b3d3;
always@(posedge clk) begin
    if(!rst_n) begin
        a1cos1 <= 9'd0;
        a2cos1 <= 9'd0;
        a3cos1 <= 9'd0;
        a1cos2 <= 9'd0;
        a2cos2 <= 9'd0;
        a3cos2 <= 9'd0;
        a1cos3 <= 9'd0;
        a2cos3 <= 9'd0;
        a3cos3 <= 9'd0;

        b1d1 <= 10'd0;
        b2d1 <= 10'd0;
        b3d1 <= 10'd0;
        b1d2 <= 10'd0;
        b2d2 <= 10'd0;
        b3d2 <= 10'd0;
        b1d3 <= 10'd0;
        b2d3 <= 10'd0;
        b3d3 <= 10'd0; 
    end else begin
        a1cos1 <= a_reg_3[3:0] * cos_abs[4:0];
        a2cos1 <= a_reg_3[7:4] * cos_abs[4:0];
        a3cos1 <= a_reg_3[11:8]* cos_abs[4:0];
        a1cos2 <= a_reg_3[3:0] * cos_abs[9:5];
        a2cos2 <= a_reg_3[7:4] * cos_abs[9:5];
        a3cos2 <= a_reg_3[11:8]* cos_abs[9:5];
        a1cos3 <= a_reg_3[3:0] * cos_abs[14:10];
        a2cos3 <= a_reg_3[7:4] * cos_abs[14:10];
        a3cos3 <= a_reg_3[11:8]* cos_abs[14:10];

        b1d1 <= b_reg_3[3:0] * div_reg_2[5:0];
        b2d1 <= b_reg_3[7:4] * div_reg_2[5:0];
        b3d1 <= b_reg_3[11:8]* div_reg_2[5:0];
        b1d2 <= b_reg_3[3:0] * div_reg_2[11:6];
        b2d2 <= b_reg_3[7:4] * div_reg_2[11:6];
        b3d2 <= b_reg_3[11:8]* div_reg_2[11:6];
        b1d3 <= b_reg_3[3:0] * div_reg_2[17:12];
        b2d3 <= b_reg_3[7:4] * div_reg_2[17:12];
        b3d3 <= b_reg_3[11:8]* div_reg_2[17:12];
    end
end

//第3级：将部分积进行合并:a_cos:27位，b_div:30位
reg sign_reg_2;
reg [26:0] a_cos;
reg [29:0] b_div;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_2 <= 1'b0;
        a_cos <= 27'd0;
        b_div <= 30'd0;
    end else begin
        sign_reg_2 <= sign_reg;
        a_cos <= a1cos1 + {a2cos1, 4'b0} + {a3cos1, 8'b0} + {a1cos2, 5'b0} + {a2cos2, 9'b0} + {a3cos2, 13'b0} + {a1cos3, 10'b0} + {a2cos3, 14'b0} + {a3cos3, 18'b0};
        b_div <= b1d1 + {b2d1,4'b0} + {b3d1,8'b0} + {b1d2,6'b0} + {b2d2,10'b0} + {b3d2,14'b0} + {b1d3,12'b0} + {b2d3,16'b0} + {b3d3,20'b0}; 
    end
end

reg sign_reg_3;
reg [26:0] a_cos_reg;
reg [29:0] b_div_reg;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_3 <= 1'b0;
        a_cos_reg <= 27'd0;
        b_div_reg <= 30'd0;
    end else begin
        sign_reg_3 <= sign_reg_2;
        a_cos_reg <= a_cos;
        b_div_reg <= b_div;
    end
end

//第4级：将a_cos和b_div以部分积相乘,a_cos27位分成6*4+3，b_div30位分成5*6
reg sign_reg_4;
reg [11:0] x1y1, x2y1, x3y1, x4y1;
reg [11:0] x1y2, x2y2, x3y2, x4y2;
reg [11:0] x1y3, x2y3, x3y3, x4y3;
reg [11:0] x1y4, x2y4, x3y4, x4y4;
reg [11:0] x1y5, x2y5, x3y5, x4y5;
reg [8:0]  x5y1, x5y2, x5y3, x5y4, x5y5;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_4 <= 1'b0;
        x1y1 <= 12'd0;
        x2y1 <= 12'd0;
        x3y1 <= 12'd0;
        x4y1 <= 12'd0;
        x1y2 <= 12'd0;
        x2y2 <= 12'd0;
        x3y2 <= 12'd0;
        x4y2 <= 12'd0;
        x1y3 <= 12'd0;
        x2y3 <= 12'd0;
        x3y3 <= 12'd0;
        x4y3 <= 12'd0;
        x1y4 <= 12'd0;
        x2y4 <= 12'd0;
        x3y4 <= 12'd0;
        x4y4 <= 12'd0; 
        x1y5 <= 12'd0;
        x2y5 <= 12'd0;
        x3y5 <= 12'd0;
        x4y5 <= 12'd0;
        x5y1 <= 9'd0;
        x5y2 <= 9'd0;
        x5y3 <= 9'd0;
        x5y4 <= 9'd0;
        x5y5 <= 9'd0;
    end else begin
        sign_reg_4 <= sign_reg_3;
        x1y1 <= a_cos_reg[5:0]   * b_div_reg[5:0];
        x2y1 <= a_cos_reg[11:6]  * b_div_reg[5:0];
        x3y1 <= a_cos_reg[17:12] * b_div_reg[5:0];
        x4y1 <= a_cos_reg[23:18] * b_div_reg[5:0];
        x5y1 <= a_cos_reg[26:24] * b_div_reg[5:0];
        x1y2 <= a_cos_reg[5:0]   * b_div_reg[11:6];
        x2y2 <= a_cos_reg[11:6]  * b_div_reg[11:6];
        x3y2 <= a_cos_reg[17:12] * b_div_reg[11:6];
        x4y2 <= a_cos_reg[23:18] * b_div_reg[11:6];
        x5y2 <= a_cos_reg[26:24] * b_div_reg[11:6]; 
        x1y3 <= a_cos_reg[5:0]   * b_div_reg[17:12];
        x2y3 <= a_cos_reg[11:6]  * b_div_reg[17:12];
        x3y3 <= a_cos_reg[17:12] * b_div_reg[17:12];
        x4y3 <= a_cos_reg[23:18] * b_div_reg[17:12];
        x5y3 <= a_cos_reg[26:24] * b_div_reg[17:12];
        x1y4 <= a_cos_reg[5:0]   * b_div_reg[23:18];
        x2y4 <= a_cos_reg[11:6]  * b_div_reg[23:18];
        x3y4 <= a_cos_reg[17:12] * b_div_reg[23:18];
        x4y4 <= a_cos_reg[23:18] * b_div_reg[23:18];
        x5y4 <= a_cos_reg[26:24] * b_div_reg[23:18];
        x1y5 <= a_cos_reg[5:0]   * b_div_reg[29:24];
        x2y5 <= a_cos_reg[11:6]  * b_div_reg[29:24];
        x3y5 <= a_cos_reg[17:12] * b_div_reg[29:24];
        x4y5 <= a_cos_reg[23:18] * b_div_reg[29:24];
        x5y5 <= a_cos_reg[26:24] * b_div_reg[29:24];
    end
end

//第5级：合并部分积:27+30=57位
reg sign_reg_5;
reg [56:0] result;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_5 <= 1'b0;
        result <= 57'd0;
    end else begin
        sign_reg_5 <= sign_reg_4;
        result <= x1y1+{x2y1,6'b0}+{x3y1,12'b0}+{x4y1,18'b0}+{x5y1,24'b0}+{x1y2,6'b0}+{x2y2,12'b0}+{x3y2,18'b0}+{x4y2,24'b0}+{x5y2,30'b0}+{x1y3,12'b0}+{x2y3,18'b0}+{x3y3,24'b0}+{x4y3,30'b0}+{x5y3,36'b0}+{x1y4,18'b0}+{x2y4,24'b0}+{x3y4,30'b0}+{x4y4,36'b0}+{x5y4,42'b0}+{x1y5,24'b0}+{x2y5,30'b0}+{x3y5,36'b0}+{x4y5,42'b0}+{x5y5,48'b0};
    end
end

//第6级：右移12位，截取12位，合并符号位
wire [11:0] result_cut;
reg sign_reg_6;
always@(posedge clk) begin
    if(!rst_n) begin
        sign_reg_6 <= 1'b0;
    end else begin
        sign_reg_6 <= sign_reg_5;
    end
end

//cos:15位，div:18位，右移33位
assign result_cut = result[32]?(result[44:33]+1'b1):result[44:33];
assign y = sign_reg_6 ? {1'b1,-result_cut} : {1'b0,result_cut};

endmodule