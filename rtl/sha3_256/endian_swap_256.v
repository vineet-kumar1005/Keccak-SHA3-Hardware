`timescale 1ns / 1ps

// Generic byte-level endian swap for SHA3-256.
// DATA_BITS must be a multiple of 8.
// Default = 256 (input width); output swap uses DATA_BITS=256 explicitly.
//
// Usage:
//   endian_swap_256 #(.DATA_BITS(MSG_BITS)) u_in  (.in_data(...), .out_data(...));
//   endian_swap_256 #(.DATA_BITS(256))      u_out (.in_data(...), .out_data(...));

module endian_swap_256 #(
    parameter DATA_BITS = 256          // Must be a multiple of 8
) (
    input  wire [DATA_BITS-1:0] in_data,
    output wire [DATA_BITS-1:0] out_data
);
    localparam NUM_BYTES = DATA_BITS / 8;

    genvar i;
    generate
        for (i = 0; i < NUM_BYTES; i = i + 1) begin : swap_loop
            assign out_data[(NUM_BYTES - 1 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate

endmodule
