`timescale 1ns / 1ps
//==============================================================
// clk_div.v  —  100 MHz → 25 MHz clock enable
//
// ZedBoard system clock is 100 MHz.
// Divides by 4 to produce a 1-cycle-wide pulse
// every 4 clocks (= 25 MHz pixel clock enable).
//==============================================================
module clk_div (
    input  wire clk_in,   // 100 MHz system clock (ZedBoard Y9)
    input  wire rst,
    output reg  clk_25    // 25 MHz clock enable (1 cycle wide)
);
    reg [1:0] cnt;        // 2-bit counter for divide-by-4

    always @(posedge clk_in) begin
        if (rst) begin
            cnt    <= 2'd0;
            clk_25 <= 1'b0;
        end else begin
            if (cnt == 2'd3) begin
                cnt    <= 2'd0;
                clk_25 <= 1'b1;
            end else begin
                cnt    <= cnt + 1;
                clk_25 <= 1'b0;
            end
        end
    end
endmodule
