`timescale 1ns / 1ps

module endian_swap_512 (
    input  wire [511:0] in_data,
    output wire [511:0] out_data
);
    genvar i;
    generate
        // Swaps the order of the 64 bytes
        for (i = 0; i < 64; i = i + 1) begin : swap_loop
            assign out_data[(63 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
endmodule