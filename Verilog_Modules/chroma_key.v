`timescale 1ns / 1ps

module chroma_key(
    input  wire        clk,
    input  wire        rst,
    input  wire        vsync,
    input  wire [23:0] hsv_in,

    input  wire        up,
    input  wire        down,
    input  wire        left,
    input  wire        right,
    input  wire        adjust_thr_en,

    output [7:0] range,
    output [7:0] h_nom,
    output [7:0] s_nom,
    output [7:0] v_nom,

    output reg         chroma_key_match
);

    localparam [7:0] H_NOMINAL     = 8'd85;
    localparam [7:0] RANGE_NOMINAL = 8'd20;
    localparam [7:0] S_MIN         = 8'd60;
    localparam [7:0] V_MIN         = 8'd40;

    reg [7:0] h_nom_q  = H_NOMINAL;
    reg [7:0] range_q  = RANGE_NOMINAL;

    assign h_nom = h_nom_q;
    assign range = range_q;
    assign s_nom = S_MIN;
    assign v_nom = V_MIN;

    wire [7:0] h = hsv_in[23:16];
    wire [7:0] s = hsv_in[15:8];
    wire [7:0] v = hsv_in[7:0];

    wire [7:0] h_min = h_nom_q - range_q;
    wire [7:0] h_max = h_nom_q + range_q;

    wire h_in_range = (h >= h_min) && (h <= h_max);
    wire s_in_range = (s >= S_MIN);
    wire v_in_range = (v >= V_MIN);

    always @(posedge clk) begin
        if (rst)
            chroma_key_match <= 1'b0;
        else
            chroma_key_match <= h_in_range && s_in_range && v_in_range;
    end

endmodule
