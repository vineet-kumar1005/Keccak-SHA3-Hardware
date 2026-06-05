`timescale 1ns / 1ps

module sha3_512_top (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,         // Pulse high to hash a new 512-bit message
    input  wire [511:0]  message_in,    // The raw 64-byte user input
    output wire          ready,         // High when ready for a new message
    output wire          done,          // High when the final hash is ready
    output wire [511:0]  hash_out       // The final SHA3-512 Digest!
);

    // Interconnect Wires
    wire          pad_done;
    wire [1599:0] padded_state_flat;
    wire [1599:0] permuted_state_flat;
    wire [511:0]  swapped_message_in;
    wire [511:0]  raw_hash_out;

    // ==========================================
    // 0. Endian Swap for Input Message
    // Aligning Verilog byte-order with FIPS 202
    // ==========================================
    endian_swap_512 swap_in_inst (
        .in_data(message_in),
        .out_data(swapped_message_in)
    );

    // ==========================================
    // 1. The Padding Phase
    // ==========================================
    sha3_512_pad_512bit padding_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .message_512(swapped_message_in), // Feeding the FIPS-aligned message
        .ready(ready),             
        .done(pad_done),           
        .block_576(),              
        .state_A_flat(padded_state_flat)
    );

    // ==========================================
    // 2. The Permutation Phase
    // ==========================================
    keccak_permutation perm_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(pad_done),          
        .state_in_flat(padded_state_flat),
        .ready(),                  
        .done(done),               
        .state_out_flat(permuted_state_flat)
    );

    // ==========================================
    // 3. The Squeezing Phase (Truncation & Swap)
    // ==========================================
    // Truncate the top 512 bits (Rate block) for the SHA3-512 digest
    assign raw_hash_out = permuted_state_flat[511:0];

    // Swap the bytes back so standard software/testbenches can read it normally
    endian_swap_512 swap_out_inst (
        .in_data(raw_hash_out),
        .out_data(hash_out)
    );

endmodule