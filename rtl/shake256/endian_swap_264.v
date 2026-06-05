`timescale 1ns / 1ps

module endian_swap_264 (
    input  wire [263:0] in_data,
    output wire [263:0] out_data
);
    genvar i;
    generate
        for (i = 0; i < 33; i = i + 1) begin : swap_loop
            assign out_data[(32 - i)*8 +: 8] = in_data[i*8 +: 8];
        end
    endgenerate
endmodule