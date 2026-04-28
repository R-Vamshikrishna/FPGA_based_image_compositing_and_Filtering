`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.02.2026 15:52:28
// Design Name: 
// Module Name: sepia
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sepia(
 input clk, rst,
 input [7:0] r_in, g_in, b_in,
 output [7:0] r_out, g_out, b_out
 );

 // Sepia conversion formulas obtained from
 // https://www.dyclassroom.com/image-processing-project/
 // how-to-convert-a-color-image-into-sepia-image

 localparam TR_R = 8'd101; // 0.393
 localparam TR_G = 8'd197; // 0.769
 localparam TR_B = 8'd48; // 0.189

 localparam TG_R = 8'd89; // 0.349
 localparam TG_G = 8'd176; // 0.686
 localparam TG_B = 8'd43; // 0.168

 localparam TB_R = 8'd70; // 0.272
 localparam TB_G = 8'd137; // 0.534
 localparam TB_B = 8'd33; // 0.131

 reg [7:0] r0_q, g0_q, b0_q;
 reg [15:0] trr_q, trg_q, trb_q; // to calculate tr
 reg [15:0] tgr_q, tgg_q, tgb_q; // to calculate tg
 reg [15:0] tbr_q, tbg_q, tbb_q; // to calculate tb
 reg [8:0] tr_q, tg_q, tb_q;
 reg [7:0] rf_q, gf_q, bf_q; // final values

 // output assignments
 assign {r_out, g_out, b_out} = {rf_q, gf_q, bf_q};

 always @(posedge clk) begin
     if(rst)begin
     {r0_q, g0_q, b0_q} <= 0;
       trr_q <= 0;
     trg_q <= 0;
     trb_q <= 0;
    
     tgr_q <= 0;;
     tgg_q <= 0;
     tgb_q <= 0;
     tbr_q <= 0;
     tbg_q <= 0;
     tbb_q <= 0;
     // clock 3: divide by 256 and add
     tr_q <= 0;
     tg_q <= 0;
     tb_q <= 0;
     // clock 4: determine outputs
     rf_q <= 0;
     gf_q <= 0;
     bf_q <= 0;
     
     end
     else begin
     // clock 1: latch inputs
     {r0_q, g0_q, b0_q} <= {r_in, g_in, b_in};
    
     // clock 2: multiplications
     trr_q <= r0_q * TR_R;
     trg_q <= g0_q * TR_G;
     trb_q <= b0_q * TR_B;
    
     tgr_q <= r0_q * TG_R;
     tgg_q <= g0_q * TG_G;
     tgb_q <= b0_q * TG_B;
     tbr_q <= r0_q * TB_R;
     tbg_q <= g0_q * TB_G;
     tbb_q <= b0_q * TB_B;
     // clock 3: divide by 256 and add
     tr_q <= trr_q[15:8] + trg_q[15:8] + trb_q[15:8];
     tg_q <= tgr_q[15:8] + tgg_q[15:8] + tgb_q[15:8];
     tb_q <= tbr_q[15:8] + tbg_q[15:8] + tbb_q[15:8];
     // clock 4: determine outputs
     rf_q <= (tr_q < 8'd255) ? tr_q[7:0] : 8'd255;
     gf_q <= (tg_q < 8'd255) ? tg_q[7:0] : 8'd255;
     bf_q <= (tb_q < 8'd255) ? tb_q[7:0] : 8'd255;
     
     end
 end
endmodule
