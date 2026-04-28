`timescale 1ns / 1ps

module grayscale(
    input  wire        clk,
    input  wire        rst,
    input  wire [7:0]  r_in, g_in, b_in,
    output wire [7:0]  r_out, g_out, b_out
);

    localparam R = 76;
    localparam G = 150;
    localparam B = 29;

    reg [7:0]  r0_q, g0_q, b0_q;
    reg [15:0] r1_q, g1_q, b1_q;
    reg [7:0]  r2_q, g2_q, b2_q;

    assign {r_out, g_out, b_out} = {r2_q, g2_q, b2_q};

    always @(posedge clk) begin
        if (rst) begin
            {r0_q, g0_q, b0_q} <= 0;
            {r1_q, g1_q, b1_q} <= 0;
            r2_q <= 0;
            g2_q <= 0;
            b2_q <= 0;
        end else begin
            {r0_q, g0_q, b0_q} <= {r_in, g_in, b_in};
            {r1_q, g1_q, b1_q} <= {R * r0_q, G * g0_q, B * b0_q};
            r2_q <= r1_q[15:8] + g1_q[15:8] + b1_q[15:8];
            g2_q <= r1_q[15:8] + g1_q[15:8] + b1_q[15:8];
            b2_q <= r1_q[15:8] + g1_q[15:8] + b1_q[15:8];
        end
    end

endmodule
