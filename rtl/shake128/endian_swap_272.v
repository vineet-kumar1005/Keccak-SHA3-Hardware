`timescale 1ns / 1ps

module endian_swap_272 (
    input  wire [271:0] in_data,
    output wire [271:0] out_data
);
    genvar i;
    generate
        // Swaps the order of the 34 bytes (272 bits / 8 = 34)
        for (i = 0; i < 34; i = i + 1) begin : swap_loop
            // Maps byte 'i' to byte '33 - i'
            assign out_data[(33 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
    
endmodule