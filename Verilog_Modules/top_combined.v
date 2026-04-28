`timescale 1ns / 1ps

module top_combined (
    input  wire        clk,
    input  wire        rst,
    input  wire        vsync,

    input  wire        enhance_en,
    input  wire        enhance_user_in_en,
    input  wire        inc_saturation,
    input  wire        dec_saturation,
    input  wire        inc_brightness,
    input  wire        dec_brightness,

    input  wire        filters_en,
    input  wire        filters_user_in_en,
    input  wire        select0,
    input  wire        select1,
    input  wire        select2,
    input  wire        select3,

    output wire [7:0]  r_out,
    output wire [7:0]  g_out,
    output wire [7:0]  b_out,
    output wire [2:0]  filter
);

    `include "param.v"

    wire [7:0] r_pipe, g_pipe, b_pipe;

    top_image_pipeline top_image_pipeline_inst (
        .clk                (clk),
        .rst                (rst),
        .vsync              (vsync),
        .enhance_en         (enhance_en),
        .enhance_user_in_en (enhance_user_in_en),
        .inc_saturation     (inc_saturation),
        .dec_saturation     (dec_saturation),
        .inc_brightness     (inc_brightness),
        .dec_brightness     (dec_brightness),
        .r_out              (r_pipe),
        .g_out              (g_pipe),
        .b_out              (b_pipe),
        .r_c                (),
        .g_c                (),
        .b_c                ()
    );

    wire [23:0] rgb_composited = {r_pipe, g_pipe, b_pipe};
    wire [23:0] rgb_filtered;

    filters filters_inst (
        .clk                (clk),
        .rst                (rst),
        .filters_en         (filters_en),
        .filters_user_in_en (filters_user_in_en),
        .select0            (select0),
        .select1            (select1),
        .select2            (select2),
        .select3            (select3),
        .rgb_in             (rgb_composited),
        .rgb_out            (rgb_filtered),
        .filter             (filter)
    );

    assign r_out = rgb_filtered[23:16];
    assign g_out = rgb_filtered[15:8];
    assign b_out = rgb_filtered[7:0];

endmodule
