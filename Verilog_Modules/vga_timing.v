`timescale 1ns / 1ps
//==============================================================
// vga_timing.v  —  640x480 @ 60 Hz VGA timing generator
//
// Displays 320x240 image 2x scaled (each pixel = 2x2 block)
//
// Pixel clock : 25.175 MHz (using 25 MHz CE from 125 MHz clk)
//
// Horizontal : 800 total  (640 active + 16 FP + 96 sync + 48 BP)
// Vertical   : 525 total  (480 active + 10 FP +  2 sync + 33 BP)
// hsync, vsync : active LOW
//==============================================================
module vga_timing (
    input  wire        clk_25,     // 25 MHz pixel clock
    input  wire        rst,
    output reg  [9:0]  hcount,     // 0..799
    output reg  [9:0]  vcount,     // 0..524
    output wire        hsync,
    output wire        vsync,
    output wire        active,
    output wire        vsync_pulse
);

    localparam H_ACTIVE = 640; localparam H_FP   = 16;
    localparam H_SYNC   = 96;  localparam H_BP   = 48;
    localparam H_TOTAL  = 800;

    localparam V_ACTIVE = 480; localparam V_FP   = 10;
    localparam V_SYNC   = 2;   localparam V_BP   = 33;
    localparam V_TOTAL  = 525;

    always @(posedge clk_25) begin
        if (rst) hcount <= 0;
        else     hcount <= (hcount == H_TOTAL-1) ? 10'd0 : hcount + 1;
    end

    always @(posedge clk_25) begin
        if (rst) vcount <= 0;
        else if (hcount == H_TOTAL-1)
            vcount <= (vcount == V_TOTAL-1) ? 10'd0 : vcount + 1;
    end

    assign hsync = ~((hcount >= H_ACTIVE+H_FP) && (hcount < H_ACTIVE+H_FP+H_SYNC));
    assign vsync = ~((vcount >= V_ACTIVE+V_FP) && (vcount < V_ACTIVE+V_FP+V_SYNC));
    assign active = (hcount < H_ACTIVE) && (vcount < V_ACTIVE);

    reg vsync_d;
    always @(posedge clk_25) vsync_d <= vsync;
    assign vsync_pulse = vsync_d && !vsync;

endmodule
