module y_gen(    
    input rst_n,       
    input [11:0] a,
    input [11:0] b,
    input [11:0] c,
    input e,
    input clk,
    output reg [12:0] y
);

wire [11:0] d;
d_gen u_d_gen(
    .clk(clk),
    .e(e),
    .rst_n(rst_n),
    .d(d)
);

//第0级：初始化，寄存变量值
reg [11:0] a_reg, b_reg;
reg [11:0] c_reg; 
reg [12:0] apd_reg;
reg [11:0] d_reg;
always@(posedge clk) begin 
       a_reg <= a;
       b_reg <= b;
       c_reg <= c;
       d_reg <= d;
       apd_reg <= a_reg + d_reg;
end

reg [9:0] c_reg_2;
reg sign;
always@(posedge clk) begin
       if(c_reg[11:10] == 2'b01) begin //当c为2047的时候，c[9:0]为1023，实际对应的是索引1
            sign <= 1'b1;
            c_reg_2 <= 1024 - c_reg[9:0];    
        end else if(c_reg[11:10] == 2'b10) begin //当c为2048的时候，c[9:0]为0,对应的索引为0
            sign <= 1'b1;   
            c_reg_2 <= c_reg[9:0];
        end else if(c_reg[11:10] == 2'b11) begin   //当c为3072的时候，c[9:0]为0，对应索引1024
            sign <= 1'b0;
            c_reg_2 <= 1024 - c_reg[9:0];
        end else if(c_reg[11:10] == 2'b00) begin //当c为1023的时候，c[9:0]
            sign <= 1'b0;
            c_reg_2 <= c_reg[9:0];
        end
end
//第1级：cos查表和div查表
wire [11:0] cos_abs;
cos_lut u_cos_lut(
    .addr(c_reg_2),   //直接通过c的后10位来查表,但是注意查表的顺序
    .cos_abs(cos_abs)
);

//根据输入apd来求索引,先右移到1-1024之间，得到idx
reg  [9:0] idx;
reg  [1:0] shift_cnt;
always@(posedge clk) begin
       if(apd_reg[12]) begin //右移3位
            idx <= apd_reg >> 3; 
            shift_cnt <= 2'd3; 
        end else if(apd_reg[11]) begin
            idx <= apd_reg >> 2; 
            shift_cnt <= 2'd2;
        end else if(apd_reg[10]) begin
            idx <= apd_reg >> 1; 
            shift_cnt <= 2'd1;
        end else begin
            idx <= apd_reg; //不需要右移
            shift_cnt <= 2'd0;
        end
end

//除法查表例化
wire  [20:0] div;
div_lut u_div_lut(
    .idx(idx),
    .div(div)
);


//根据右移的次数对结果进行还原(延时了两个周期)
reg [20:0] div_val;
always@(posedge clk) begin
       case(shift_cnt)
            2'd0: begin
                div_val <= div; 
            end
            2'd1: begin
                div_val <= div >> 1; 
            end
            2'd2: begin
                div_val <= div >> 2;
            end
            2'd3: begin
                div_val <= div >> 3; 
            end
        endcase
end

reg  [11:0] cos_reg;
reg  [11:0] a_reg_2;
reg  [11:0] b_reg_2;
always@(posedge clk) begin
       a_reg_2 <= a_reg;
       b_reg_2 <= b_reg;
       cos_reg <= cos_abs;
end

//第2级：提取符号和绝对值
reg sign_reg_2;
reg [11:0] a_reg_3;
reg [11:0] b_reg_3;
always@(posedge clk) begin
       sign_reg_2 <= sign;
       a_reg_3 <= a_reg_2;
       b_reg_3 <= b_reg_2;
end


//cos:12位，div:21位，a,b：12位，a_cos:4+5=9位，b_div:4+6=10位
//减少分段，不然的话加分器太多延迟太高
reg sign_reg_3;
reg [11:0] a1cos1, a2cos1;
reg [11:0] a1cos2, a2cos2;

reg [12:0] b1d1, b2d1;
reg [12:0] b1d2, b2d2;
reg [12:0] b1d3, b2d3;

always@(posedge clk) begin
       sign_reg_3 <= sign_reg_2;
       a1cos1 <= a_reg_3[5:0] *  cos_reg[5:0];
       a2cos1 <= a_reg_3[11:6] * cos_reg[5:0];
       a1cos2 <= a_reg_3[5:0] *  cos_reg[11:6];
       a2cos2 <= a_reg_3[11:6] * cos_reg[11:6];

       b1d1 <= b_reg_3[5:0] *  div_val[6:0];
       b2d1 <= b_reg_3[11:6] * div_val[6:0];
       b1d2 <= b_reg_3[5:0] *  div_val[13:7];
       b2d2 <= b_reg_3[11:6] * div_val[13:7];
       b1d3 <= b_reg_3[5:0] *  div_val[20:14];
       b2d3 <= b_reg_3[11:6] * div_val[20:14];
end

reg sign_reg_4;
reg [17:0] a_cos_1;
reg [17:0] a_cos_2;
reg [18:0] b_div_1;
reg [18:0] b_div_2;
reg [18:0] b_div_3;
always@(posedge clk) begin
       sign_reg_4 <= sign_reg_3;
       a_cos_1 <= a1cos1 + {a2cos1,6'b0};
       a_cos_2 <= a1cos2 + {a2cos2,6'b0};

       b_div_1 <= b1d1 + {b2d1,6'b0};
       b_div_2 <= b1d2 + {b2d2,6'b0};
       b_div_3 <= b1d3 + {b2d3,6'b0};
end

reg [23:0] a_cos;
reg [32:0] b_div;
reg sign_reg_5;
always@(posedge clk) begin
       sign_reg_5 <= sign_reg_4;
       a_cos <= a_cos_1 + {a_cos_2,6'b0};
       b_div <= b_div_1 + {b_div_2,7'b0} + {b_div_3,14'b0};
end

reg [23:0] a_cos_reg;
reg sign_reg_6;
always@(posedge clk) begin
       sign_reg_6 <= sign_reg_5;
       a_cos_reg <= a_cos;
end

reg sign_reg_7;
reg [14:0] x1y1,x2y1,x3y1,x4y1;
reg [14:0] x1y2,x2y2,x3y2,x4y2;
reg [14:0] x1y3,x2y3,x3y3,x4y3;
reg [11:0] x1y4,x2y4,x3y4,x4y4;
always@(posedge clk) begin
    sign_reg_7 <= sign_reg_6;
	x1y1 <= a_cos_reg[5:0] 		* b_div[8:0];
	x2y1 <= a_cos_reg[11:6] 	* b_div[8:0];
	x3y1 <= a_cos_reg[17:12]	* b_div[8:0];
	x4y1 <= a_cos_reg[23:18]	* b_div[8:0];
	
	x1y2 <=  a_cos_reg[5:0] 	* b_div[17:9];
	x2y2 <=  a_cos_reg[11:6]    * b_div[17:9];
	x3y2 <=  a_cos_reg[17:12]   * b_div[17:9];
	x4y2 <=  a_cos_reg[23:18]   * b_div[17:9];
	
	x1y3 <=  a_cos_reg[5:0] 	* b_div[26:18];
	x2y3 <=  a_cos_reg[11:6]    * b_div[26:18];
	x3y3 <=  a_cos_reg[17:12]   * b_div[26:18];
	x4y3 <=  a_cos_reg[23:18]   * b_div[26:18];

	x1y4 <=  a_cos_reg[5:0] 	* b_div[32:27];
	x2y4 <=  a_cos_reg[11:6]    * b_div[32:27];
	x3y4 <=  a_cos_reg[17:12]   * b_div[32:27];
	x4y4 <=  a_cos_reg[23:18]   * b_div[32:27];
end

reg sign_reg_8;
reg [20:0] stage1_1, stage1_2;
reg [20:0] stage2_1, stage2_2;
reg [20:0] stage3_1, stage3_2;
reg [17:0] stage4_1, stage4_2;
always@(posedge clk) begin
    sign_reg_8 <= sign_reg_7;
	stage1_1 <= x1y1 + {x2y1,6'b0};
	stage1_2 <= x3y1 + {x4y1,6'b0};
	stage2_1 <= x1y2 + {x2y2,6'b0};
	stage2_2 <= x3y2 + {x4y2,6'b0};
	stage3_1 <= x1y3 + {x2y3,6'b0};
	stage3_2 <= x3y3 + {x4y3,6'b0};
	stage4_1 <= x1y4 + {x2y4,6'b0};
	stage4_2 <= x3y4 + {x4y4,6'b0};
end

reg sign_reg_9;
reg [32:0] layer1,layer2,layer3;
reg [29:0] layer4;
always@(posedge clk) begin
    sign_reg_9 <= sign_reg_8;
	layer1 <= stage1_1 + {stage1_2,12'b0};
	layer2 <= stage2_1 + {stage2_2,12'b0};
	layer3 <= stage3_1 + {stage3_2,12'b0};
	layer4 <= stage4_1 + {stage4_2,12'b0};
end

reg sign_reg_10;
reg [41:0] layer1p2;
reg [38:0] layer3p4;
always@(posedge clk) begin
    sign_reg_10 <= sign_reg_9;
	layer1p2 <= layer1 + {layer2,9'b0};
	layer3p4 <= layer3 + {layer4,9'b0};
end

reg sign_reg_11;
reg [56:0] result;
always@(posedge clk) begin
    sign_reg_11 <= sign_reg_10;
	result <= layer1p2 + {layer3p4,18'b0};
end


//第6级：右移12位，截取12位，合并符号位
wire [11:0] result_cut;
wire [12:0] result_sign;
//cos:12位，div:21位，右移33位
assign result_cut = result[44:33];
assign result_sign = sign_reg_11 ? {1'b1,-result_cut} : {1'b0,result_cut};

always@(posedge clk) begin
       y <= result_sign;
end

endmodule
