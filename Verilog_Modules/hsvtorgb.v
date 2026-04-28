`timescale 1ns / 1ps

module hsvtorgb (
    input  wire        clk,
    input  wire        rst,
    input  wire [23:0] hsv_in,    // {H,S,V}
    output wire [23:0] rgb_out    // {R,G,B}
);

    // Split HSV
    wire [7:0] h = hsv_in[23:16];
    wire [7:0] s = hsv_in[15:8];
    wire [7:0] v = hsv_in[7:0];

    // Latched inputs
    reg [7:0] h_q, s_q, v_q;

    reg [3:0] hue_region_q;
    reg [5:0] hue_remainder_q;
    reg [7:0] hue_remainder255_q;

    reg [10:0] h6_q;
    reg [7:0]  hue_sum_q;

    reg [15:0] p0_q, q0_q, t0_q;
    reg [15:0] p1_q, q1_q, t1_q;
    reg [15:0] p2_q, q2_q, t2_q;
    reg [15:0] p3_q, q3_q, t3_q;

    reg [7:0] h1_q, h2_q;
    reg [7:0] s1_q, s2_q, s3_q, s4_q, s5_q;
    reg [7:0] v1_q, v2_q, v3_q, v4_q, v5_q, v6_q, v7_q, v8_q;
    reg [3:0] hrg1_q, hrg2_q, hrg3_q, hrg4_q, hrg5_q, hrg6_q;

    reg [7:0] r_q, g_q, b_q;

    assign rgb_out = {r_q, g_q, b_q};

    always @(posedge clk) begin
        if (rst) begin
            // reset everything (important for simulation)
            h_q <= 0; s_q <= 0; v_q <= 0;
            h6_q <= 0; hue_region_q <= 0; hue_sum_q <= 0;
            hue_remainder_q <= 0; hue_remainder255_q <= 0;

            p0_q <= 0; q0_q <= 0; t0_q <= 0;
            p1_q <= 0; q1_q <= 0; t1_q <= 0;
            p2_q <= 0; q2_q <= 0; t2_q <= 0;
            p3_q <= 0; q3_q <= 0; t3_q <= 0;

            h1_q <= 0; h2_q <= 0;
            s1_q <= 0; s2_q <= 0; s3_q <= 0; s4_q <= 0; s5_q <= 0;
            v1_q <= 0; v2_q <= 0; v3_q <= 0; v4_q <= 0;
            v5_q <= 0; v6_q <= 0; v7_q <= 0; v8_q <= 0;

            hrg1_q <= 0; hrg2_q <= 0; hrg3_q <= 0;
            hrg4_q <= 0; hrg5_q <= 0; hrg6_q <= 0;

            r_q <= 0; g_q <= 0; b_q <= 0;
        end
        else begin
            // Clock 1
            {h_q, s_q, v_q} <= {h, s, v};

            // Clock 2
            h6_q <= 6 * h_q;
            {h1_q, s1_q, v1_q} <= {h_q, s_q, v_q};

            // Clock 3
            hue_region_q <= h6_q[10:8];
            hue_sum_q <= 8'd43 * h6_q[10:8];
            {h2_q, s2_q, v2_q} <= {h1_q, s1_q, v1_q};

            // Clock 4
            hue_remainder_q <= h2_q - hue_sum_q;
            {s3_q, v3_q} <= {s2_q, v2_q};
            hrg1_q <= hue_region_q;

            // Clock 5
            hue_remainder255_q <= 6 * hue_remainder_q;
            {s4_q, v4_q} <= {s3_q, v3_q};
            hrg2_q <= hrg1_q;

            // Clock 6
            p0_q <= 8'd255 - s4_q;
            q0_q <= hue_remainder255_q;
            t0_q <= 8'd255 - hue_remainder255_q;
            {s5_q, v5_q} <= {s4_q, v4_q};
            hrg3_q <= hrg2_q;

            // Clock 7
            p1_q <= v5_q * p0_q;
            q1_q <= s5_q * q0_q;
            t1_q <= s5_q * t0_q;
            v6_q <= v5_q;
            hrg4_q <= hrg3_q;

            // Clock 8
            p2_q <= p1_q;
            q2_q <= 8'd255 - q1_q[15:8];
            t2_q <= 8'd255 - t1_q[15:8];
            v7_q <= v6_q;
            hrg5_q <= hrg4_q;

            // Clock 9
            p3_q <= p2_q;
            q3_q <= v7_q * q2_q;
            t3_q <= v7_q * t2_q;
            v8_q <= v7_q;
            hrg6_q <= hrg5_q;

            // Clock 10
            case (hrg6_q)
                0: begin r_q <= v8_q;        g_q <= t3_q[15:8]; b_q <= p3_q[15:8]; end
                1: begin r_q <= q3_q[15:8]; g_q <= v8_q;        b_q <= p3_q[15:8]; end
                2: begin r_q <= p3_q[15:8]; g_q <= v8_q;        b_q <= t3_q[15:8]; end
                3: begin r_q <= p3_q[15:8]; g_q <= q3_q[15:8]; b_q <= v8_q;        end
                4: begin r_q <= t3_q[15:8]; g_q <= p3_q[15:8]; b_q <= v8_q;        end
                default:
                   begin r_q <= v8_q;        g_q <= p3_q[15:8]; b_q <= q3_q[15:8]; end
            endcase
        end
    end
endmodule
