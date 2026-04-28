`timescale 1ns / 1ps
//==============================================================
// zybo_vga_top.v  —  Top-level for ZedBoard
//
// Image : 320x240 pixels in fg.mem / bg.mem (24bpp hex)
//         Displayed 2x scaled on 640x480 VGA (each pixel = 2x2)
// Board : Digilent ZedBoard (XC7Z020)
// Clock : 100 MHz on Y9  →  clk_div ÷4 → 25 MHz pixel CE
//
// Controls:
//   SW[0] = filters_en   (enable filter processing)
//   SW[1] = enhance_en   (enable brightness/saturation)
//   SW[2] = select0      (filter select bit 0)
//   SW[3] = select1      (filter select bit 1)
//
// Filter select (SW[3]:SW[2]):
//   00 = SEPIA
//   01 = INVERT
//   10 = EDGE
//   11 = CARTOON
//
//   BTN[0] = inc_brightness   BTN[1] = dec_brightness
//   BTN[2] = inc_saturation   BTN[3] = dec_saturation
//
// LED[0] = filters_en   LED[1] = enhance_en
// LED[3:2] = active filter index
//==============================================================
module zybo_vga_top (
    input  wire        clk,        // 100 MHz (ZedBoard Y9)
    input  wire [3:0]  sw,
    input  wire [3:0]  btn,
    output wire        vga_hs,
    output wire        vga_vs,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire [3:0]  led
);

    `include "param.v"

    // ── Power-on reset ─────────────────────────────────────────
    reg [7:0] rst_cnt = 8'hFF;
    wire rst = rst_cnt[7];
    always @(posedge clk)
        if (rst_cnt != 0) rst_cnt <= rst_cnt - 1;

    // ── 25 MHz pixel clock enable (÷5 from 125 MHz) ───────────
    wire pix_ce;
    clk_div u_clkdiv (.clk_in(clk), .rst(rst), .clk_25(pix_ce));

    // ── VGA timing counters (gated by pix_ce) ─────────────────
    localparam H_ACTIVE = 640; localparam H_FP = 16;
    localparam H_SYNC   = 96;  localparam H_BP = 48;
    localparam H_TOTAL  = 800;
    localparam V_ACTIVE = 480; localparam V_FP = 10;
    localparam V_SYNC   = 2;   localparam V_BP = 33;
    localparam V_TOTAL  = 525;

    reg [9:0] hcount = 0, vcount = 0;
    reg       hsync_r = 1, vsync_r = 1, active_r = 0;

    always @(posedge clk) begin
        if (rst) begin
            hcount <= 0; vcount <= 0;
            hsync_r <= 1; vsync_r <= 1; active_r <= 0;
        end else if (pix_ce) begin
            hcount  <= (hcount == H_TOTAL-1) ? 10'd0 : hcount + 1;
            if (hcount == H_TOTAL-1)
                vcount <= (vcount == V_TOTAL-1) ? 10'd0 : vcount + 1;
            hsync_r  <= ~((hcount >= H_ACTIVE+H_FP) && (hcount < H_ACTIVE+H_FP+H_SYNC));
            vsync_r  <= ~((vcount >= V_ACTIVE+V_FP) && (vcount < V_ACTIVE+V_FP+V_SYNC));
            active_r <= (hcount < H_ACTIVE) && (vcount < V_ACTIVE);
        end
    end

    // ── Button debounce ────────────────────────────────────────
    reg [19:0] dbnc [0:3];
    reg [3:0]  btn_db;
    genvar bi;
    generate
        for (bi = 0; bi < 4; bi = bi + 1) begin : DBNC
            always @(posedge clk) begin
                dbnc[bi]   <= btn[bi] ? dbnc[bi] + 1 : 20'd0;
                btn_db[bi] <= (dbnc[bi] == 20'hFFFFF);
            end
        end
    endgenerate

    // ── Control signals ────────────────────────────────────────
    wire filters_en         = sw[0];
    wire enhance_en         = sw[1];
    wire select0            = sw[2];
    wire select1            = sw[3];
    wire filters_user_in_en = 1'b1;
    wire enhance_user_in_en = 1'b1;
    wire inc_brightness     = btn_db[0];
    wire dec_brightness     = btn_db[1];
    wire inc_saturation     = btn_db[2];
    wire dec_saturation     = btn_db[3];

    // ── Image pipeline ─────────────────────────────────────────
    wire [7:0] r_out_pipe, g_out_pipe, b_out_pipe;
    wire [2:0] filter_sel;

    top_combined top_inst (
        .clk                (clk),
        .rst                (rst),
        .pix_ce             (pix_ce),
        .hcount             (hcount),
        .vcount             (vcount),
        .active             (active_r),
        .vsync              (vsync_r),
        .enhance_en         (enhance_en),
        .enhance_user_in_en (enhance_user_in_en),
        .inc_saturation     (inc_saturation),
        .dec_saturation     (dec_saturation),
        .inc_brightness     (inc_brightness),
        .dec_brightness     (dec_brightness),
        .filters_en         (filters_en),
        .filters_user_in_en (filters_user_in_en),
        .select0            (select0),
        .select1            (select1),
        .select2            (1'b0),
        .select3            (1'b0),
        .r_out              (r_out_pipe),
        .g_out              (g_out_pipe),
        .b_out              (b_out_pipe),
        .filter             (filter_sel)
    );

    // ── Pipeline latency delay ────────────────────────────────
    // Pipeline stages (all clocked at 100 MHz):
    //   ROM read      :  1 cycle
    //   rgbtohsv      :  4 cycles  (was 3; +1 for divide pipeline fix)
    //   chroma_key    :  1 cycle
    //   enhance       :  1 cycle
    //   hsvtorgb      : 10 cycles
    //   filters (mux) :  0 cycles (combinational)
    //   TOTAL         : 17 cycles
    localparam PIPE_LATENCY = 17;
    reg [PIPE_LATENCY-1:0] active_delay = 0;
    always @(posedge clk)
        active_delay <= {active_delay[PIPE_LATENCY-2:0], active_r};
    wire active_valid = active_delay[PIPE_LATENCY-1];

    // ── VGA outputs ────────────────────────────────────────────
    assign vga_hs = hsync_r;
    assign vga_vs = vsync_r;
    assign vga_r  = active_valid ? r_out_pipe[7:4] : 4'b0000;
    assign vga_g  = active_valid ? g_out_pipe[7:4] : 4'b0000;
    assign vga_b  = active_valid ? b_out_pipe[7:4] : 4'b0000;

    // ── LEDs ───────────────────────────────────────────────────
    assign led[0]   = filters_en;
    assign led[1]   = enhance_en;
    assign led[3:2] = filter_sel[1:0];

endmodule
