`timescale 1ns / 1ps

module shake256_top (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [263:0]  message_in,    
    output wire          ready,
    output wire          done,
    output wire [1023:0] hash_out       
);

    // Interconnect Wires
    wire          pad_done;
    wire [1599:0] padded_state_flat;
    wire [1599:0] permuted_state_flat;
    wire [263:0]  swapped_message_in;   // 33 bytes
    wire [1023:0] raw_hash_out;         // 136 bytes

    // 0. Input Endian Swap (264-bit / 33 bytes)
    endian_swap_264 swap_in_inst (
        .in_data(message_in),
        .out_data(swapped_message_in)
    );

    // 1. Padding Phase (SHAKE256, 33-byte input)
    shake256_pad_264bit padding_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .message_264(swapped_message_in),
        .ready(ready),             
        .done(pad_done),           
        .block_1088(),             
        .state_A_flat(padded_state_flat)
    );

    // 2. Permutation Engine
    keccak_permutation perm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(pad_done),          
        .state_in_flat(padded_state_flat),
        .ready(),                  
        .done(done),               
        .state_out_flat(permuted_state_flat)
    );

    // 3. The Squeezing Phase
    assign raw_hash_out = permuted_state_flat[1023:0];

    // 4. Output Endian Swap (1088-bit / 136 bytes)
    endian_swap_1024 swap_out_inst (
        .in_data(raw_hash_out),
        .out_data(hash_out)
    );

endmodule