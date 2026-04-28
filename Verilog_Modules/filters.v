`timescale 1ns / 1ps

module filters (
    input  wire        clk,
    input  wire        rst,
    input  wire        filters_en,
    input  wire        filters_user_in_en,
    input  wire        select0,
    input  wire        select1,
    input  wire        select2,
    input  wire        select3,
    input  wire [23:0] rgb_in,
    output wire [23:0] rgb_out,
    output wire [2:0]  filter
);

    `include "param.v"

    reg [2:0] filter_q = GRAYSCALE;

    wire sel_all = select0 && select1 && select2 && select3;

    always @(posedge clk) begin
        if (filters_en && filters_user_in_en) begin
            if (select0 && !select1 && !select2 && !select3) filter_q <= SEPIA;
            if (select1 && !select0 && !select2 && !select3) filter_q <= INVERT;
            if (select2 && !select0 && !select1 && !select3) filter_q <= EDGE;
            if (select3 && !select0 && !select1 && !select2) filter_q <= CARTOON;
            if (sel_all)                                      filter_q <= GRAYSCALE;
        end
    end

    wire [23:0] rgb_sepia;
    wire [23:0] rgb_invert;
    wire [23:0] rgb_gray;
    wire [23:0] rgb_edge;
    wire [23:0] rgb_cartoon;

    sepia sepia_filter (
        .clk(clk), .rst(rst),
        .r_in(rgb_in[23:16]), .g_in(rgb_in[15:8]), .b_in(rgb_in[7:0]),
        .r_out(rgb_sepia[23:16]), .g_out(rgb_sepia[15:8]), .b_out(rgb_sepia[7:0])
    );

    invert invert_filter (
        .clk(clk), .rst(rst),
        .r_in(rgb_in[23:16]), .g_in(rgb_in[15:8]), .b_in(rgb_in[7:0]),
        .r_out(rgb_invert[23:16]), .g_out(rgb_invert[15:8]), .b_out(rgb_invert[7:0])
    );

    grayscale grayscale_filter (
        .clk(clk), .rst(rst),
        .r_in(rgb_in[23:16]), .g_in(rgb_in[15:8]), .b_in(rgb_in[7:0]),
        .r_out(rgb_gray[23:16]), .g_out(rgb_gray[15:8]), .b_out(rgb_gray[7:0])
    );

    cartoon cartoon_filter (
        .clk(clk), .rst(rst),
        .rgb_gray(rgb_gray[7:0]),
        .rgb_in(rgb_in),
        .rgb_edge(rgb_edge),
        .rgb_cartoon(rgb_cartoon)
    );

    assign filter  = filter_q;
    assign rgb_out = (!filters_en)           ? rgb_in      :
                     (filter_q == SEPIA)     ? rgb_sepia   :
                     (filter_q == INVERT)    ? rgb_invert  :
                     (filter_q == EDGE)      ? rgb_edge    :
                     (filter_q == CARTOON)   ? rgb_cartoon :
                     (filter_q == GRAYSCALE) ? rgb_gray    : rgb_in;

endmodule
