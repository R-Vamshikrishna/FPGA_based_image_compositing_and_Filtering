`timescale 1ns / 1ps

module top_image_pipeline (
    input  wire        clk,
    input  wire        rst,
    input  wire        enhance_en,
    input  wire        enhance_user_in_en,
    input  wire        inc_saturation,
    input  wire        dec_saturation,
    input  wire        inc_brightness,
    input  wire        dec_brightness,
    input  wire        vsync,
    output wire [7:0]  r_out,
    output wire [7:0]  g_out,
    output wire [7:0]  b_out,
    output wire [7:0]  r_c,
    output wire [7:0]  g_c,
    output wire [7:0]  b_c
);

    reg [17:0] pixel_addr;
    reg        vsync_d;

    always @(posedge clk) begin
        if (rst) begin
            pixel_addr <= 18'd0;
            vsync_d    <= 1'b0;
        end else begin
            vsync_d <= vsync;
            if (!vsync_d && vsync)
                pixel_addr <= 18'd0;
            else if (pixel_addr < 18'd262143)
                pixel_addr <= pixel_addr + 1'b1;
        end
    end

    wire [23:0] fg_rgb;
    wire [23:0] bg_rgb;

    image_rom #(.MEM_FILE("fg.mem")) fg_image_rom (
        .clk(clk),
        .addr(pixel_addr),
        .data_out(fg_rgb)
    );

    image_rom #(.MEM_FILE("bg.mem")) bg_image_rom (
        .clk(clk),
        .addr(pixel_addr),
        .data_out(bg_rgb)
    );

    wire [23:0] fg_hsv;

    rgbtohsv fg_rgbtohsv (
        .clk(clk),
        .rst(rst),
        .rgb_in(fg_rgb),
        .hsv_out(fg_hsv)
    );

    wire chroma_key_match_raw;

    chroma_key chroma_key_inst (
        .clk(clk),
        .rst(rst),
        .vsync(vsync),
        .hsv_in(fg_hsv),
        .up(1'b0), .down(1'b0), .left(1'b0), .right(1'b0),
        .adjust_thr_en(1'b0),
        .chroma_key_match(chroma_key_match_raw)
    );

    wire [23:0] fg_hsv_enhanced;

    enhance enhance_inst (
        .clk(clk),
        .rst(rst),
        .vsync(vsync),
        .enhance_en(enhance_en),
        .enhance_user_in_en(enhance_user_in_en),
        .inc_saturation(inc_saturation),
        .dec_saturation(dec_saturation),
        .inc_brightness(inc_brightness),
        .dec_brightness(dec_brightness),
        .hsv_in(fg_hsv),
        .hsv_out(fg_hsv_enhanced)
    );

    wire [23:0] fg_rgb_final;

    hsvtorgb hsvtorgb_inst (
        .clk(clk),
        .rst(rst),
        .hsv_in(fg_hsv_enhanced),
        .rgb_out(fg_rgb_final)
    );

    // fg_rgb_final total latency: ROM(1) + rgbtohsv(3) + enhance(1) + hsvtorgb(10) = 15
    // chroma_key_match latency:   ROM(1) + rgbtohsv(3) + chroma_key(1)             =  5
    // bg_rgb latency:             ROM(1)                                            =  1
    // bg_rgb needs 14 more cycles, chroma_key_match needs 10 more cycles

    localparam BG_DELAY = 14;
    reg [23:0] bg_delay_pipe [0:BG_DELAY-1];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < BG_DELAY; i = i + 1)
                bg_delay_pipe[i] <= 24'd0;
        end else begin
            bg_delay_pipe[0] <= bg_rgb;
            for (i = 1; i < BG_DELAY; i = i + 1)
                bg_delay_pipe[i] <= bg_delay_pipe[i-1];
        end
    end
    wire [23:0] bg_rgb_aligned = bg_delay_pipe[BG_DELAY-1];

    localparam CK_DELAY = 10;
    reg [CK_DELAY-1:0] ck_delay_pipe;
    always @(posedge clk) begin
        if (rst)
            ck_delay_pipe <= {CK_DELAY{1'b0}};
        else
            ck_delay_pipe <= {ck_delay_pipe[CK_DELAY-2:0], chroma_key_match_raw};
    end
    wire chroma_key_match = ck_delay_pipe[CK_DELAY-1];

    assign r_out = chroma_key_match ? bg_rgb_aligned[23:16] : fg_rgb_final[23:16];
    assign g_out = chroma_key_match ? bg_rgb_aligned[15:8]  : fg_rgb_final[15:8];
    assign b_out = chroma_key_match ? bg_rgb_aligned[7:0]   : fg_rgb_final[7:0];

    assign r_c = fg_rgb_final[23:16];
    assign g_c = fg_rgb_final[15:8];
    assign b_c = fg_rgb_final[7:0];

endmodule
