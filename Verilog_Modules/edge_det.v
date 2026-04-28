`timescale 1ns / 1ps

module edge_det (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] gradient,
    output reg         pixel_edge,
    output reg         cartoon_edge
);

    `include "param.v"

    always @(posedge clk) begin
        if (rst) begin
            pixel_edge   <= 1'b0;
            cartoon_edge <= 1'b0;
        end else begin
            pixel_edge   <= (gradient > GRADIENT_EDGE_THRESHOLD);
            cartoon_edge <= (gradient > CARTOON_EDGE_THRESHOLD);
        end
    end

endmodule
