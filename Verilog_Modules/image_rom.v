`timescale 1ns / 1ps

module image_rom #(
    parameter MEM_FILE = "image.mem",
    parameter ADDR_WIDTH = 18   // 512x512 = 262144
)(
    input  wire                  clk,
    input  wire [ADDR_WIDTH-1:0]  addr,
    output reg  [23:0]            data_out
);

    reg [23:0] image_mem [0:(1<<ADDR_WIDTH)-1];

    initial begin
        $readmemh(MEM_FILE, image_mem);
    end

    always @(posedge clk) begin
        data_out <= image_mem[addr];
    end

endmodule
