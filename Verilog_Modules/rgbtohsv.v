`timescale 1ns / 1ps

module rgbtohsv (
    input  wire        clk,
    input  wire        rst,
    input  wire [23:0] rgb_in,
    output reg  [23:0] hsv_out
);

    wire [7:0] r = rgb_in[23:16];
    wire [7:0] g = rgb_in[15:8];
    wire [7:0] b = rgb_in[7:0];

    reg [7:0] max_c, min_c;
    reg [7:0] r1, g1, b1;

    reg [7:0] delta;
    reg [7:0] max_c2, min_c2;
    reg [7:0] r2, g2, b2;

    reg [7:0] h_calc, s_calc, v_calc;

    wire [8:0] g_minus_b = {1'b0, g1} - {1'b0, b1};
    wire [8:0] b_minus_r = {1'b0, b1} - {1'b0, r1};
    wire [8:0] r_minus_g = {1'b0, r1} - {1'b0, g1};

    wire [7:0] g_minus_b_abs = g_minus_b[8] ? (~g_minus_b[7:0] + 1) : g_minus_b[7:0];
    wire [7:0] b_minus_r_abs = b_minus_r[8] ? (~b_minus_r[7:0] + 1) : b_minus_r[7:0];
    wire [7:0] r_minus_g_abs = r_minus_g[8] ? (~r_minus_g[7:0] + 1) : r_minus_g[7:0];

    always @(posedge clk) begin
        if (rst) begin
            max_c  <= 0; min_c  <= 0;
            r1     <= 0; g1     <= 0; b1 <= 0;
            delta  <= 0; max_c2 <= 0; min_c2 <= 0;
            r2     <= 0; g2     <= 0; b2 <= 0;
            hsv_out <= 24'd0;
        end else begin

            // Stage 1: compute max and min, latch RGB
            max_c <= (r >= g && r >= b) ? r :
                     (g >= r && g >= b) ? g : b;
            min_c <= (r <= g && r <= b) ? r :
                     (g <= r && g <= b) ? g : b;
            r1 <= r;
            g1 <= g;
            b1 <= b;

            // Stage 2: compute delta, latch stage-1 results
            delta  <= max_c - min_c;
            max_c2 <= max_c;
            min_c2 <= min_c;
            r2 <= r1;
            g2 <= g1;
            b2 <= b1;

            // Stage 3: compute H, S, V from stable delta/max_c2
            v_calc <= max_c2;

            if (max_c2 == 0)
                s_calc <= 0;
            else
                s_calc <= (delta * 16'd255) / max_c2;

            if (delta == 0) begin
                h_calc <= 0;
            end else if (max_c2 == r2) begin
                if (g2 >= b2)
                    h_calc <= (8'd43 * g_minus_b_abs) / delta;
                else
                    h_calc <= 8'd255 - (8'd43 * g_minus_b_abs) / delta;
            end else if (max_c2 == g2) begin
                if (b2 >= r2)
                    h_calc <= 8'd85 + (8'd43 * b_minus_r_abs) / delta;
                else
                    h_calc <= 8'd85 - (8'd43 * b_minus_r_abs) / delta;
            end else begin
                if (r2 >= g2)
                    h_calc <= 8'd171 + (8'd43 * r_minus_g_abs) / delta;
                else
                    h_calc <= 8'd171 - (8'd43 * r_minus_g_abs) / delta;
            end

            hsv_out <= {h_calc, s_calc, v_calc};
        end
    end

endmodule
