`timescale 1ns / 1ps

module endian_swap_1024 (
    input  wire [1023:0] in_data,
    output wire [1023:0] out_data
);
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : swap_loop
            assign out_data[(127 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
endmodule