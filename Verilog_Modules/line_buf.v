`timescale 1ns / 1ps

module line_buf #(parameter ELEM_LEN = 8) (
    input  wire                clk,
    input  wire                rst,
    input  wire [ELEM_LEN-1:0] pixel_in,
    output wire [ELEM_LEN-1:0] a0, a1, a2,
    output wire [ELEM_LEN-1:0] a7, pix, a3,
    output wire [ELEM_LEN-1:0] a6, a5, a4
);

    `include "param.v"

    // Single shift register of depth 2*LINE_LEN + 3
    // Index 0 = newest pixel, index DEPTH-1 = oldest pixel
    //
    // 3x3 window taps:
    //   a0  a1  a2   <- top row    (oldest, 2 lines back)
    //   a7  pix a3   <- middle row (1 line back)
    //   a6  a5  a4   <- bottom row (newest pixels)
    //
    // Bottom row taps  : sr[2],       sr[1],           sr[0]
    // Middle row taps  : sr[LINE_LEN+2], sr[LINE_LEN+1], sr[LINE_LEN]
    // Top row taps     : sr[2*LINE_LEN+2], sr[2*LINE_LEN+1], sr[2*LINE_LEN]

    localparam DEPTH = 2 * LINE_LEN + 3;

    reg [ELEM_LEN-1:0] sr [0:DEPTH-1];

    integer j;

    always @(posedge clk) begin
        if (rst) begin
            for (j = 0; j < DEPTH; j = j + 1)
                sr[j] <= {ELEM_LEN{1'b0}};
        end else begin
            sr[0] <= pixel_in;
            for (j = 1; j < DEPTH; j = j + 1)
                sr[j] <= sr[j-1];
        end
    end

    // Bottom row (newest)
    assign a6  = sr[2];
    assign a5  = sr[1];
    assign a4  = sr[0];

    // Middle row
    assign a7  = sr[LINE_LEN + 2];
    assign pix = sr[LINE_LEN + 1];
    assign a3  = sr[LINE_LEN];

    // Top row (oldest)
    assign a0  = sr[2*LINE_LEN + 2];
    assign a1  = sr[2*LINE_LEN + 1];
    assign a2  = sr[2*LINE_LEN];

endmodule
