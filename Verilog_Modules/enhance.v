`timescale 1ns / 1ps
module enhance #(
    parameter RGB2HSV_LATENCY = 5   
)(
    input  wire        clk,
    input  wire        rst,
    input  wire        vsync,
    input  wire        enhance_en,
    input  wire        enhance_user_in_en,
    input  wire        inc_saturation,
    input  wire        dec_saturation,
    input  wire        inc_brightness,
    input  wire        dec_brightness,
    input  wire [23:0] hsv_in,
    output reg  [23:0] hsv_out,
    output wire [7:0]  s_offset,
    output wire [7:0]  v_offset,
    output wire        s_dir,
    output wire        v_dir
);

    parameter S_DEV = 5 ;   // make effect visible
    parameter V_DEV = 160;

    reg [RGB2HSV_LATENCY-1:0] vsync_pipe;

    always @(posedge clk) begin
        if (rst)
            vsync_pipe <= 0;
        else
            vsync_pipe <= {vsync_pipe[RGB2HSV_LATENCY-2:0], vsync};
    end

    wire vsync_aligned = vsync_pipe[RGB2HSV_LATENCY-1];

    // Falling edge detect
    reg vsync_q;
    always @(posedge clk) vsync_q <= vsync_aligned;

    wire vsync_falling = vsync_q && !vsync_aligned;

    reg [7:0] s_offset_q, v_offset_q;
    reg       s_dir_q, v_dir_q;

    assign s_offset = s_offset_q;
    assign v_offset = v_offset_q;
    assign s_dir    = s_dir_q;
    assign v_dir    = v_dir_q;

    wire zero_saturation = inc_saturation && dec_saturation;
    wire zero_brightness = inc_brightness && dec_brightness;

    wire reset_enhance = enhance_user_in_en &&
                         zero_saturation &&
                         zero_brightness;

    // -------------------------------------------------
    // Offset update (ONCE PER FRAME)
    // -------------------------------------------------
    always @(posedge clk) begin
        if (rst || reset_enhance) begin
            s_offset_q <= 0;
            v_offset_q <= 0;
            s_dir_q    <= 0;
            v_dir_q    <= 0;
        end
        else if (vsync_falling && enhance_user_in_en) begin

            // -------- Saturation --------
            if (inc_saturation && !dec_saturation) begin
                s_dir_q <= 1'b1;
                if (s_offset_q < (8'd255 - S_DEV))
                    s_offset_q <= s_offset_q + S_DEV;
            end
            else if (dec_saturation && !inc_saturation) begin
                s_dir_q <= 1'b0;
                if (s_offset_q > S_DEV)
                    s_offset_q <= s_offset_q - S_DEV;
                else
                    s_offset_q <= 0;
            end

            // -------- Brightness --------
            if (inc_brightness && !dec_brightness) begin
                v_dir_q <= 1'b1;
                if (v_offset_q < (8'd255 - V_DEV))
                    v_offset_q <= v_offset_q + V_DEV;
            end
            else if (dec_brightness && !inc_brightness) begin
                v_dir_q <= 1'b0;
                if (v_offset_q > V_DEV)
                    v_offset_q <= v_offset_q - V_DEV;
                else
                    v_offset_q <= 0;
            end
        end
    end

    // -------------------------------------------------
    // Apply enhancement (1 cycle)
    // -------------------------------------------------
    always @(posedge clk) begin
        if (!enhance_en)
            hsv_out <= hsv_in;
        else begin
            hsv_out[23:16] <= hsv_in[23:16]; // Hue unchanged

            // Saturation
            if (s_dir_q)
                hsv_out[15:8] <= (hsv_in[15:8] + s_offset_q > 8'hFF)
                               ? 8'hFF : hsv_in[15:8] + s_offset_q;
            else
                hsv_out[15:8] <= (hsv_in[15:8] > s_offset_q)
                               ? hsv_in[15:8] - s_offset_q : 8'd0;

            // Brightness
            if (v_dir_q)
                hsv_out[7:0] <= (hsv_in[7:0] + v_offset_q > 8'hFF)
                              ? 8'hFF : hsv_in[7:0] + v_offset_q;
            else
                hsv_out[7:0] <= (hsv_in[7:0] > v_offset_q)
                              ? hsv_in[7:0] - v_offset_q : 8'd0;
        end
    end

endmodule