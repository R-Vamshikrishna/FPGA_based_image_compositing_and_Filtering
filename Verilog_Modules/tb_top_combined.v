`timescale 1ns / 1ps

module tb_top_combined;

    parameter CLK_PERIOD   = 10;
    parameter TOTAL_PIXELS = 262144; // 512x512

    // Pipeline latency breakdown:
    // top_image_pipeline = 15 cycles
    // grayscale          =  3 cycles
    // line_buf           =  2*512 + 3 = 1027 cycles
    // sobel_op           =  4 cycles
    // edge_det           =  1 cycle
    // Total              =  1050 cycles
    //
    // Add one full extra line (512) as margin to ensure alignment.
    // This guarantees the first captured pixel is pixel 0 of the output frame.
    parameter PIPELINE_LAT = 1050 + 512;

    reg clk, rst, vsync;
    reg enhance_en, enhance_user_in_en;
    reg inc_saturation, dec_saturation;
    reg inc_brightness, dec_brightness;
    reg filters_en, filters_user_in_en;
    reg select0, select1, select2, select3;

    wire [7:0] r_out, g_out, b_out;
    wire [2:0] filter;

    always #(CLK_PERIOD/2) clk = ~clk;

    top_combined dut (
        .clk(clk), .rst(rst), .vsync(vsync),
        .enhance_en(enhance_en), .enhance_user_in_en(enhance_user_in_en),
        .inc_saturation(inc_saturation), .dec_saturation(dec_saturation),
        .inc_brightness(inc_brightness), .dec_brightness(dec_brightness),
        .filters_en(filters_en), .filters_user_in_en(filters_user_in_en),
        .select0(select0), .select1(select1),
        .select2(select2), .select3(select3),
        .r_out(r_out), .g_out(g_out), .b_out(b_out),
        .filter(filter)
    );

    integer outfile;
    integer pixel_count;

    initial begin
        clk   = 0; rst = 1; vsync = 1;
        pixel_count = 0;
        enhance_en = 0; enhance_user_in_en = 0;
        inc_saturation = 0; dec_saturation = 0;
        inc_brightness = 0; dec_brightness = 0;
        filters_en = 1; filters_user_in_en = 1;

        // Select filter: select2 only = EDGE, select3 only = CARTOON
        select0 = 0; select1 = 0; select2 = 0; select3 =0;

        // Hold reset for 20 cycles
        repeat(20) @(posedge clk);
        rst = 0;

        // vsync pulse to start frame
        @(posedge clk); vsync = 0;
        repeat(5) @(posedge clk); vsync = 1;

        // Wait for pipeline to fill - use full PIPELINE_LAT
        repeat(PIPELINE_LAT) @(posedge clk);

        $display("Pipeline ready. filter=%0d", filter);

        outfile = $fopen("combined_output.mem", "w");
        if (outfile == 0) begin
            $display("ERROR: cannot open output file"); $finish;
        end

        while (pixel_count < TOTAL_PIXELS) begin
            @(posedge clk);
            $fwrite(outfile, "%02h%02h%02h\n", r_out, g_out, b_out);
            pixel_count = pixel_count + 1;
        end

        $fclose(outfile);
        $display("Done. %0d pixels written.", pixel_count);
        $finish;
    end

endmodule