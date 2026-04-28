`timescale 1ns / 1ps

module sobel_op (
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  a0, a1, a2,
    input  wire [7:0]  a7, a3,
    input  wire [7:0]  a6, a5, a4,
    output wire [15:0] gradient
);
    // Gx kernel:        Gy kernel:
    // -1  0  1          1  2  1
    // -2  0  2          0  0  0
    // -1  0  1         -1 -2 -1
    //
    // gx = (a2+2*a3+a4) - (a0+2*a7+a6)
    // gy = (a0+2*a1+a2) - (a6+2*a5+a4)

    // Stage 1 regs
    reg [7:0] a0r, a1r, a2r, a7r, a3r, a6r, a5r, a4r;
    // Stage 2 regs
    reg signed [10:0] gx_r, gy_r;
    // Stage 3 regs
    reg [10:0] abs_gx_r, abs_gy_r;
    // Stage 4 reg
    reg [15:0] grad_r;

    assign gradient = grad_r;

    always @(posedge clk) begin
        if (rst) begin
            a0r<=0; a1r<=0; a2r<=0;
            a7r<=0; a3r<=0;
            a6r<=0; a5r<=0; a4r<=0;
            gx_r<=0; gy_r<=0;
            abs_gx_r<=0; abs_gy_r<=0;
            grad_r<=0;
        end else begin
            // Stage 1: latch
            a0r<=a0; a1r<=a1; a2r<=a2;
            a7r<=a7; a3r<=a3;
            a6r<=a6; a5r<=a5; a4r<=a4;

            // Stage 2: compute gradients (11-bit signed to avoid overflow)
            gx_r <= ($signed({1'b0,a2r}) + $signed({1'b0,a3r<<1}) + $signed({1'b0,a4r}))
                  - ($signed({1'b0,a0r}) + $signed({1'b0,a7r<<1}) + $signed({1'b0,a6r}));
            gy_r <= ($signed({1'b0,a0r}) + $signed({1'b0,a1r<<1}) + $signed({1'b0,a2r}))
                  - ($signed({1'b0,a6r}) + $signed({1'b0,a5r<<1}) + $signed({1'b0,a4r}));

            // Stage 3: absolute values
            abs_gx_r <= gx_r[10] ? -gx_r : gx_r;
            abs_gy_r <= gy_r[10] ? -gy_r : gy_r;

            // Stage 4: sum
            grad_r <= abs_gx_r + abs_gy_r;
        end
    end

endmodule
