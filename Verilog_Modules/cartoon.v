`timescale 1ns / 1ps

module cartoon (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  rgb_gray,
    input  wire [23:0] rgb_in,
    output wire [23:0] rgb_edge,
    output wire [23:0] rgb_cartoon
);

    `include "param.v"

    // -------------------------------------------------------
    // SOBEL PATH: grayscale -> line_buf -> sobel_op -> edge_det
    // Latency: LINE_BUF_DLY + SOBEL_OP_DLY + EDGE_DET_DLY
    // -------------------------------------------------------
    wire [7:0] s_a0,s_a1,s_a2,s_a7,s_pix,s_a3,s_a6,s_a5,s_a4;

    line_buf #(8) sobel_buf (
        .clk(clk), .rst(rst), .pixel_in(rgb_gray),
        .a0(s_a0),.a1(s_a1),.a2(s_a2),
        .a7(s_a7),.pix(s_pix),.a3(s_a3),
        .a6(s_a6),.a5(s_a5),.a4(s_a4)
    );

    wire [15:0] gradient;
    sobel_op sobel_inst (
        .clk(clk), .rst(rst),
        .a0(s_a0),.a1(s_a1),.a2(s_a2),
        .a7(s_a7),.a3(s_a3),
        .a6(s_a6),.a5(s_a5),.a4(s_a4),
        .gradient(gradient)
    );

    wire pixel_edge_w, cartoon_edge_w;
    edge_det edge_det_inst (
        .clk(clk), .rst(rst),
        .gradient(gradient),
        .pixel_edge(pixel_edge_w),
        .cartoon_edge(cartoon_edge_w)
    );

    // -------------------------------------------------------
    // GAUSSIAN PATH: rgb_in -> line_buf (per channel) -> gaussian
    // Latency: LINE_BUF_DLY + GAUSSIAN_DLY
    // -------------------------------------------------------
    wire [2:0] gr_a0,gr_a1,gr_a2,gr_a7,gr_pix,gr_a3,gr_a6,gr_a5,gr_a4;
    wire [2:0] gg_a0,gg_a1,gg_a2,gg_a7,gg_pix,gg_a3,gg_a6,gg_a5,gg_a4;
    wire [1:0] gb_a0,gb_a1,gb_a2,gb_a7,gb_pix,gb_a3,gb_a6,gb_a5,gb_a4;

    line_buf #(3) gauss_r_buf (
        .clk(clk), .rst(rst), .pixel_in(rgb_in[23:21]),
        .a0(gr_a0),.a1(gr_a1),.a2(gr_a2),
        .a7(gr_a7),.pix(gr_pix),.a3(gr_a3),
        .a6(gr_a6),.a5(gr_a5),.a4(gr_a4)
    );

    line_buf #(3) gauss_g_buf (
        .clk(clk), .rst(rst), .pixel_in(rgb_in[15:13]),
        .a0(gg_a0),.a1(gg_a1),.a2(gg_a2),
        .a7(gg_a7),.pix(gg_pix),.a3(gg_a3),
        .a6(gg_a6),.a5(gg_a5),.a4(gg_a4)
    );

    line_buf #(2) gauss_b_buf (
        .clk(clk), .rst(rst), .pixel_in(rgb_in[7:6]),
        .a0(gb_a0),.a1(gb_a1),.a2(gb_a2),
        .a7(gb_a7),.pix(gb_pix),.a3(gb_a3),
        .a6(gb_a6),.a5(gb_a5),.a4(gb_a4)
    );

    wire [7:0] rgb_gauss;
    gaussian gauss_inst (
        .clk(clk), .rst(rst),
        .a0r(gr_a0),.a1r(gr_a1),.a2r(gr_a2),.a7r(gr_a7),.pix_r(gr_pix),.a3r(gr_a3),.a6r(gr_a6),.a5r(gr_a5),.a4r(gr_a4),
        .a0g(gg_a0),.a1g(gg_a1),.a2g(gg_a2),.a7g(gg_a7),.pix_g(gg_pix),.a3g(gg_a3),.a6g(gg_a6),.a5g(gg_a5),.a4g(gg_a4),
        .a0b(gb_a0),.a1b(gb_a1),.a2b(gb_a2),.a7b(gb_a7),.pix_b(gb_pix),.a3b(gb_a3),.a6b(gb_a6),.a5b(gb_a5),.a4b(gb_a4),
        .rgb_out(rgb_gauss)
    );

    // -------------------------------------------------------
    // Delay gaussian output to align with sobel edge output
    // Sobel total latency  : LINE_BUF_DLY + SOBEL_OP_DLY + EDGE_DET_DLY
    // Gaussian total latency: LINE_BUF_DLY + GAUSSIAN_DLY
    // Extra delay needed   : SOBEL_OP_DLY + EDGE_DET_DLY - GAUSSIAN_DLY
    // -------------------------------------------------------
    localparam EXTRA_DLY = SOBEL_OP_DLY + EDGE_DET_DLY - GAUSSIAN_DLY;

    reg [7:0] gauss_dly [0:EXTRA_DLY-1];
    integer k;
    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < EXTRA_DLY; k = k + 1)
                gauss_dly[k] <= 8'd0;
        end else begin
            gauss_dly[0] <= rgb_gauss;
            for (k = 1; k < EXTRA_DLY; k = k + 1)
                gauss_dly[k] <= gauss_dly[k-1];
        end
    end

    wire [7:0]  rgb_color      = gauss_dly[EXTRA_DLY-1];
    wire [23:0] rgb_color_24   = {rgb_color[7:5],5'd0, rgb_color[4:2],5'd0, rgb_color[1:0],6'd0};

    assign rgb_edge    = pixel_edge_w   ?  24'hFFFFFF : 24'h000000;
    assign rgb_cartoon = cartoon_edge_w ? 24'h000000 : rgb_color_24;

endmodule