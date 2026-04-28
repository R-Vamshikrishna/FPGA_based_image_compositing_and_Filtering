`timescale 1ns / 1ps

module gaussian(
    input  wire        clk,
    input  wire        rst,
    input  wire [2:0]  a0r, a1r, a2r,
    input  wire [2:0]  a7r, pix_r, a3r,
    input  wire [2:0]  a6r, a5r, a4r,
    input  wire [2:0]  a0g, a1g, a2g,
    input  wire [2:0]  a7g, pix_g, a3g,
    input  wire [2:0]  a6g, a5g, a4g,
    input  wire [1:0]  a0b, a1b, a2b,
    input  wire [1:0]  a7b, pix_b, a3b,
    input  wire [1:0]  a6b, a5b, a4b,
    output wire [7:0]  rgb_out
);

    reg [2:0] a0r_q, a1r_q, a2r_q, a7r_q, pix_r_q, a3r_q, a6r_q, a5r_q, a4r_q;
    reg [2:0] a0g_q, a1g_q, a2g_q, a7g_q, pix_g_q, a3g_q, a6g_q, a5g_q, a4g_q;
    reg [1:0] a0b_q, a1b_q, a2b_q, a7b_q, pix_b_q, a3b_q, a6b_q, a5b_q, a4b_q;

    reg [6:0] r_sum_q;
    reg [6:0] g_sum_q;
    reg [5:0] b_sum_q;

    reg [2:0] r_out_q;
    reg [2:0] g_out_q;
    reg [1:0] b_out_q;

    assign rgb_out = {r_out_q, g_out_q, b_out_q};

    always @(posedge clk) begin
        if (rst) begin
            a0r_q <= 0; a1r_q <= 0; a2r_q <= 0;
            a7r_q <= 0; pix_r_q <= 0; a3r_q <= 0;
            a6r_q <= 0; a5r_q <= 0; a4r_q <= 0;
            a0g_q <= 0; a1g_q <= 0; a2g_q <= 0;
            a7g_q <= 0; pix_g_q <= 0; a3g_q <= 0;
            a6g_q <= 0; a5g_q <= 0; a4g_q <= 0;
            a0b_q <= 0; a1b_q <= 0; a2b_q <= 0;
            a7b_q <= 0; pix_b_q <= 0; a3b_q <= 0;
            a6b_q <= 0; a5b_q <= 0; a4b_q <= 0;
            r_sum_q <= 0; g_sum_q <= 0; b_sum_q <= 0;
            r_out_q <= 0; g_out_q <= 0; b_out_q <= 0;
        end else begin
            // Stage 1: latch inputs
            {a0r_q,a1r_q,a2r_q} <= {a0r,a1r,a2r};
            {a7r_q,pix_r_q,a3r_q} <= {a7r,pix_r,a3r};
            {a6r_q,a5r_q,a4r_q} <= {a6r,a5r,a4r};
            {a0g_q,a1g_q,a2g_q} <= {a0g,a1g,a2g};
            {a7g_q,pix_g_q,a3g_q} <= {a7g,pix_g,a3g};
            {a6g_q,a5g_q,a4g_q} <= {a6g,a5g,a4g};
            {a0b_q,a1b_q,a2b_q} <= {a0b,a1b,a2b};
            {a7b_q,pix_b_q,a3b_q} <= {a7b,pix_b,a3b};
            {a6b_q,a5b_q,a4b_q} <= {a6b,a5b,a4b};

            // Stage 2: apply Gaussian kernel (1 2 1 / 2 4 2 / 1 2 1), divide by 16
            r_sum_q <= a0r_q + (a1r_q<<1) + a2r_q + (a7r_q<<1) + (pix_r_q<<2) + (a3r_q<<1) + a6r_q + (a5r_q<<1) + a4r_q;
            g_sum_q <= a0g_q + (a1g_q<<1) + a2g_q + (a7g_q<<1) + (pix_g_q<<2) + (a3g_q<<1) + a6g_q + (a5g_q<<1) + a4g_q;
            b_sum_q <= a0b_q + (a1b_q<<1) + a2b_q + (a7b_q<<1) + (pix_b_q<<2) + (a3b_q<<1) + a6b_q + (a5b_q<<1) + a4b_q;

            // Stage 3: take top bits (divide by 16)
            r_out_q <= r_sum_q[6:4];
            g_out_q <= g_sum_q[6:4];
            b_out_q <= b_sum_q[5:4];
        end
    end

endmodule
