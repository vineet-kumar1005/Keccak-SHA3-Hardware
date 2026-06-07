`timescale 1ns / 1ps

module endian_swap_512 #(
    parameter MSG_BITS = 512          
) (
    input  wire [MSG_BITS-1:0] in_data,
    output wire [MSG_BITS-1:0] out_data
);
    localparam NUM_BYTES = MSG_BITS / 8;
 
    genvar i;
    generate
        // Swap the byte order: byte 0 <-> byte (NUM_BYTES-1), etc.
        for (i = 0; i < NUM_BYTES; i = i + 1) begin : swap_loop
            assign out_data[(NUM_BYTES - 1 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
endmodule