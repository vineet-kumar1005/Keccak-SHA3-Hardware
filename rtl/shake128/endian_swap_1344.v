`timescale 1ns / 1ps

module endian_swap_1344 (
    input  wire [1343:0] in_data,
    output wire [1343:0] out_data
);
    genvar i;
    generate
        // Swaps the order of the 168 bytes (1344 bits / 8 = 168)
        for (i = 0; i < 168; i = i + 1) begin : swap_loop
            // Maps byte 'i' to byte '167 - i'
            assign out_data[(167 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
    
endmodule