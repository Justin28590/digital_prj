module stage5(
    input           clk,
    input           rst,
    input [10:0]    a,
    input [10:0]    b,
    input [10:0]    c,
    input           e,
    output reg [11:0]   y
    // ports
);

    /*----reg for stage 0----*/
    reg [10:0] rega, regb, regc;
    reg [9:0] regd;
    wire [9:0] regd_wire;
    /*----reg for stage 0----*/

    /*----reg for stage 1----*/
    wire [12:0] cos_val_wire;
    reg [12:0] cos_val_reg;
    reg [10:0] rega_stage1;
    reg [11:0] regapb_stage1;
    /*----reg for stage 1----*/

    /*----reg for stage 2----*/
    reg [10:0] rega_stage2;
    wire [20:0] div_val_wire;
    reg [20:0] div_val_reg;
    reg [12:0] cos_val_reg_stage2;
    reg [12:0] cos_val_reg_stage2_abs;
    /*----reg for stage 2----*/

    /*----reg for stage 3----*/
    reg res_sign_stage3;
    reg [12:0] middle_res_ahdh, middle_res_ahdm, middle_res_ahdl;
    reg [11:0] middle_res_aldh, middle_res_aldm, middle_res_aldl;
    reg [10:0] middle_res_dhch, middle_res_dlch;
    reg [11:0] middle_res_dhcl, middle_res_dlcl;
    /*----reg for stage 3----*/

    /*----reg for stage 4----*/
    reg res_sign_stage4;
    reg [31:0] full_res_div_a;
    reg [22:0] full_res_cos_d;
    wire [13:0] res_div_a;
    wire [12:0] res_cos_d;
    assign res_div_a = full_res_div_a[31:18];
    assign res_cos_d = full_res_cos_d[22:10];
    /*----reg for stage 4----*/

    /*----reg for stage 5----*/         //流水线同时对5个数进行计算
    reg res_sign_stage5;
    reg [13:0] middle_res_a0b0;
    reg [13:0] middle_res_a0b1;
    reg [13:0] middle_res_a0b2;
    reg [8:0] middle_res_a0b3;

    reg [13:0] middle_res_a1b0;
    reg [13:0] middle_res_a1b1;
    reg [13:0] middle_res_a1b2;
    reg [8:0] middle_res_a1b3;

    reg [13:0] middle_res_a2b0;
    reg [13:0] middle_res_a2b1;
    reg [13:0] middle_res_a2b2;
    reg [8:0] middle_res_a2b3;

    reg [13:0] middle_res_a3b0;
    reg [13:0] middle_res_a3b1;
    reg [13:0] middle_res_a3b2;
    reg [8:0] middle_res_a3b3;

    reg [10:0] middle_res_a4b0;
    reg [10:0] middle_res_a4b1;
    reg [10:0] middle_res_a4b2;
    reg [5:0] middle_res_a4b3;
    /*----reg for stage 5----*/

    /*----reg for stage 6----*/
    reg res_sign_stage6;
    reg [54:0] full_res_final1;
    reg [54:0] full_res_final2;
    reg [54:0] full_res_final3;
    reg [54:0] full_res_final4;
    /*----reg for stage 6----*/

    /*----reg for stage 7----*/
    reg res_sign_stage7;
    reg [54:0] full_res_final;
    wire [11:0] full_res_final_wire_tmp;
    wire [11:0] full_res_final_wire;
    
    /*----reg for stage 7----*/

    // pipeline lut instances
    cos_lut u_cos_lut(
        .c          (regc           ),
        .cos_val    (cos_val_wire   )
    );
    div_lut u_div_lut(
        .apb        (regapb_stage1),
        .div_val    (div_val_wire)
    );
    asyn u_asyn(
        .clk        (clk            ),
        .e          (e              ),
        .res_e      (regd_wire      )
    );

    /*--------stage 0--------*/
    always @(posedge clk) begin
        if (rst) begin
            rega <= 0; regb <= 0; regc <= 0;
        end else begin
            rega <= a;
            regb <= b;
            regc <= c;
            regd <= regd_wire;
        end
    end
    /*--------stage 0--------*/
    /*--------stage 1--------*/
    always @(posedge clk) begin
        if (rst) begin
            cos_val_reg <= 0; regapb_stage1 <= 0;
        end else begin
            cos_val_reg <= cos_val_wire;
            regapb_stage1 <= rega + regb;
            rega_stage1 <= rega;
        end
    end
    /*--------stage 1--------*/
    /*--------stage 2--------*/
    always @(posedge clk) begin
        if (rst) begin
            cos_val_reg_stage2 <= 0;
            div_val_reg <= 0;
        end else begin
            cos_val_reg_stage2 <= cos_val_reg;
            cos_val_reg_stage2_abs <= (cos_val_reg[12]) ? (~cos_val_reg + 12'b1) : (cos_val_reg);
            rega_stage2 <= rega_stage1;
            div_val_reg <= div_val_wire;
        end
    end
    /*--------stage 2--------*/
    /*--------stage 3--------*/
    always @(posedge clk) begin
        if (rst) begin
            res_sign_stage3 <= 0;
            middle_res_ahdh <= 0; middle_res_ahdm <= 0; middle_res_ahdl <= 0;   //a high div high
            middle_res_aldh <= 0; middle_res_aldm <= 0; middle_res_aldl <= 0;
        end else begin
            /*---preserve signed---*/
            res_sign_stage3 <= cos_val_reg_stage2[12];
            /*---preserve signed---*/
            /*---compute a x div---*/           //ad*cos/(a+b)*2^11
            middle_res_ahdh <= rega_stage2[10:5] * div_val_reg[20:14];
            middle_res_ahdm <= rega_stage2[10:5] * div_val_reg[13:7];
            middle_res_ahdl <= rega_stage2[10:5] * div_val_reg[6:0];
            middle_res_aldh <= rega_stage2[4:0] * div_val_reg[20:14];
            middle_res_aldm <= rega_stage2[4:0] * div_val_reg[13:7];
            middle_res_aldl <= rega_stage2[4:0] * div_val_reg[6:0];
            /*---compute a x div---*/
            /*---compute cos x d---*/
            middle_res_dhch <= regd[9:5] * cos_val_reg_stage2_abs[12:7];
            middle_res_dlch <= regd[4:0] * cos_val_reg_stage2_abs[12:7];
            middle_res_dhcl <= regd[9:5] * cos_val_reg_stage2_abs[6:0];
            middle_res_dlcl <= regd[4:0] * cos_val_reg_stage2_abs[6:0];
            /*---compute cos x d---*/
        end
    end
    /*--------stage 3--------*/
    /*--------stage 4--------*/
    always @(posedge clk) begin
        if (rst) begin
            res_sign_stage4 <= 0;
            full_res_div_a <= 0; full_res_cos_d <= 0;
        end else begin
            res_sign_stage4 <= res_sign_stage3;
            full_res_div_a <= {middle_res_ahdh, 19'b0} + {middle_res_ahdm, 12'b0} + {middle_res_ahdl, 5'b0} + {middle_res_aldh, 14'b0} + {middle_res_aldm, 7'b0} + middle_res_aldl;
            full_res_cos_d <= {middle_res_dhch, 12'b0} + {middle_res_dlch, 7'b0} + {middle_res_dhcl, 5'b0} + middle_res_dlcl;
        end
    end
    /*--------stage 4--------*/
    /*--------stage 5--------*/
    always @(posedge clk)
        if (rst) begin
            res_sign_stage5 <= 0;
            middle_res_a0b0 <= 0;
            middle_res_a0b1 <= 0;
            middle_res_a0b2 <= 0;
            middle_res_a0b3 <= 0;

            middle_res_a1b0 <= 0;
            middle_res_a1b1 <= 0;
            middle_res_a1b2 <= 0;
            middle_res_a1b3 <= 0;

            middle_res_a2b0 <= 0;
            middle_res_a2b1 <= 0;
            middle_res_a2b2 <= 0;
            middle_res_a2b3 <= 0;

            middle_res_a3b0 <= 0;
            middle_res_a3b1 <= 0;
            middle_res_a3b2 <= 0;
            middle_res_a3b3 <= 0;

            middle_res_a4b0 <= 0;
            middle_res_a4b1 <= 0;
            middle_res_a4b2 <= 0;
            middle_res_a4b3 <= 0;
        end
         else begin
            res_sign_stage5 <= res_sign_stage4;
            middle_res_a0b0 <=full_res_div_a[6:0]*full_res_cos_d[6:0];
            middle_res_a0b1 <=full_res_div_a[6:0]*full_res_cos_d[13:7] ;
            middle_res_a0b2 <=full_res_div_a[6:0]*full_res_cos_d[20:14] ;
            middle_res_a0b3 <=full_res_div_a[6:0]*full_res_cos_d[22:21] ;
            middle_res_a1b0 <=full_res_div_a[13:7]*full_res_cos_d[6:0] ;
            middle_res_a1b1 <=full_res_div_a[13:7]*full_res_cos_d[13:7] ;
            middle_res_a1b2 <=full_res_div_a[13:7]*full_res_cos_d[20:14] ;
            middle_res_a1b3 <=full_res_div_a[13:7]*full_res_cos_d[22:21] ;
            middle_res_a2b0 <=full_res_div_a[20:14]*full_res_cos_d[6:0] ;
            middle_res_a2b1 <=full_res_div_a[20:14]*full_res_cos_d[13:7] ;
            middle_res_a2b2 <=full_res_div_a[20:14]*full_res_cos_d[20:14] ;
            middle_res_a2b3 <=full_res_div_a[20:14]*full_res_cos_d[22:21] ;
            middle_res_a3b0 <=full_res_div_a[27:21]*full_res_cos_d[6:0] ;
            middle_res_a3b1 <=full_res_div_a[27:21]*full_res_cos_d[13:7] ;
            middle_res_a3b2 <=full_res_div_a[27:21]*full_res_cos_d[20:14] ;
            middle_res_a3b3 <=full_res_div_a[27:21]*full_res_cos_d[22:21] ;
            middle_res_a4b0 <=full_res_div_a[31:28]*full_res_cos_d[6:0] ;
            middle_res_a4b1 <=full_res_div_a[31:28]*full_res_cos_d[13:7] ;
            middle_res_a4b2 <=full_res_div_a[31:28]*full_res_cos_d[20:14] ;
            middle_res_a4b3 <=full_res_div_a[31:28]*full_res_cos_d[22:21] ;
        end
    /*--------stage 5--------*/
    /*--------stage 6--------*/
    always @(posedge clk) begin
        if (rst) begin
            res_sign_stage6 <= 0;
            full_res_final1 <= 0;
            full_res_final2 <= 0;
            full_res_final3 <= 0;
            full_res_final4 <= 0;
        end else begin
            res_sign_stage6 <= res_sign_stage5;
            full_res_final1 <=  middle_res_a0b0 + {middle_res_a0b1, 7'b0} + {middle_res_a0b2, 14'b0} + {middle_res_a0b3, 21'b0}
                                +{ middle_res_a4b3 , 49'b0};
            full_res_final2 <=  {middle_res_a1b0, 7'b0}+{middle_res_a1b1, 14'b0}+{middle_res_a1b2, 21'b0}+{ middle_res_a1b3 , 28'b0}
                                +{middle_res_a4b2, 42'b0};
            full_res_final3 <=  {middle_res_a2b0, 14'b0}+{middle_res_a2b1, 21'b0}+{middle_res_a2b2, 28'b0}+{ middle_res_a2b3 , 35'b0}
                                +{middle_res_a4b1, 35'b0};
            full_res_final4 <=  {middle_res_a3b0, 21'b0}+{middle_res_a3b1, 28'b0}+{middle_res_a3b2, 35'b0}+{ middle_res_a3b3 , 42'b0}
                                +{middle_res_a4b0, 28'b0};

        end
    end
    /*--------stage 7--------*/
    /*--------stage 7--------*/
    always @(posedge clk) begin
        if(rst)begin
            full_res_final<=0; res_sign_stage7 <= 0;
        end else begin
            res_sign_stage7 <= res_sign_stage6;
            full_res_final <= full_res_final1+full_res_final2+full_res_final3+full_res_final4;
        end
    end
    /*--------stage 7--------*/
    /*--------stage 8--------*/
    always @(posedge clk) begin
        if (rst) begin
            y <= 0;
        end else begin
            y <= full_res_final_wire;
            // y <= full_res_final[31] ? (full_res_final_wire + 12'b1) : full_res_final_wire;
        end
    end
    /*--------stage 8--------*/

    assign full_res_final_wire_tmp = (full_res_final[31]) ? (full_res_final[43:32] + 12'b1) : full_res_final[43:32];
    assign full_res_final_wire = (res_sign_stage7) ? (~(full_res_final_wire_tmp) + 12'b1) : full_res_final_wire_tmp;
 //top
endmodule
