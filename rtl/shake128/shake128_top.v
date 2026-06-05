`timescale 1ns / 1ps

module shake128_top (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,
    input  wire [271:0]  message_in,    // 34-byte input
    output wire          ready,
    output wire          done,
    output wire [1343:0] hash_out       // 168-byte output
);

    // Interconnect Wires
    wire          pad_done;
    wire [1599:0] padded_state_flat;
    wire [1599:0] permuted_state_flat;
    wire [271:0]  swapped_message_in;
    
    // =======================================================
    // FIX 1: This internal wire MUST be 1344 bits! 
    // If it was left at [511:0] or [271:0], the higher bits get dropped.
    // =======================================================
    wire [1343:0] raw_hash_out; 

    // 0. Input Endian Swap (272-bit)
    endian_swap_272 swap_in_inst (
        .in_data(message_in),
        .out_data(swapped_message_in)
    );

    // 1. Padding Phase 
    // (Note: Your screenshot showed 'shake12_pad_272bit.v'. Make sure the module name matches your file!)
    shake128_pad_272bit padding_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .message_272(swapped_message_in),
        .ready(ready),             
        .done(pad_done),           
        .block_1344(),             
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

    // 3. The Squeezing Phase (Truncation)
    assign raw_hash_out = permuted_state_flat[1343:0];

    // =======================================================
    // FIX 2: You MUST instantiate the 1344-bit swap module here!
    // If you accidentally used 'endian_swap_272', it leaves 1072 output pins floating (z).
    // =======================================================
    endian_swap_1344 swap_out_inst (
        .in_data(raw_hash_out),
        .out_data(hash_out)
    );

endmodule