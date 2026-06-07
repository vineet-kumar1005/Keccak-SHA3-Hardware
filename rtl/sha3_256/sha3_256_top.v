`timescale 1ns / 1ps

// SHA3-256 Top Level — parameterized input message width.
//
// Parameter
// ---------
//   MSG_BITS : Number of input message bits.
//              Must be a multiple of 8 and less than 1088 (the SHA3-256 rate).
//              Default = 256 (32 bytes).
//
// Usage examples
// --------------
//   sha3_256_top #(.MSG_BITS(256)) u (.message_in(my_256b), ...);  // default
//   sha3_256_top #(.MSG_BITS(128)) u (.message_in(my_128b), ...);  // 16-byte msg
//   sha3_256_top #(.MSG_BITS(512)) u (.message_in(my_512b), ...);  // 64-byte msg
//
// Output is always SHA3-256: a 256-bit digest.
//
// Pipeline (combinational pad, no FSM)
// -------------------------------------
//   start → endian_swap (comb) → pad (comb) → keccak_permutation (FSM, 26 cycles)
//   Cycle 0 : start asserted; pad output immediately valid; permutation latches.
//   Cycles 1-25 : permutation running; ready = 0.
//   Cycle 26 : done pulses high; ready returns to 1.

module sha3_256_top #(
    parameter MSG_BITS = 256
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [MSG_BITS-1:0]   message_in,   // Raw user input (MSG_BITS wide)
    output wire                  ready,         // From permutation — the only stall source
    output wire                  done,
    output wire [255:0]          hash_out       // SHA3-256 digest (always 256 bits)
);

    // -----------------------------------------------------------------------
    // Internal wires
    // -----------------------------------------------------------------------
    wire [MSG_BITS-1:0] swapped_message_in;
    wire [1087:0]       block_1088_unused;
    wire [1599:0]       padded_state_flat;
    wire                pad_done;               // = start (combinational pass-through)
    wire [1599:0]       permuted_state_flat;
    wire [255:0]        raw_hash_out;
    wire                perm_ready;

    // -----------------------------------------------------------------------
    // 0. Endian-swap the input (MSG_BITS wide)
    // -----------------------------------------------------------------------
    endian_swap_256 #(.DATA_BITS(MSG_BITS)) swap_in_inst (
        .in_data (message_in),
        .out_data(swapped_message_in)
    );

    // -----------------------------------------------------------------------
    // 1. Padding — purely combinational, no FSM
    //    pad_done = start (same cycle); state_A_flat valid whenever message is.
    // -----------------------------------------------------------------------
    sha3_256_pad_256bit #(.MSG_BITS(MSG_BITS)) padding_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .message_256(swapped_message_in),
        .ready      (),                    // always 1 — unused here
        .done       (pad_done),
        .block_1088 (block_1088_unused),   // unused at top level
        .state_A_flat(padded_state_flat)
    );

    // -----------------------------------------------------------------------
    // 2. Keccak-f[1600] permutation — 24-round FSM (unchanged)
    //    Latches state_A_flat on the posedge where pad_done (= start) is high.
    // -----------------------------------------------------------------------
    keccak_permutation perm_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (pad_done),
        .state_in_flat(padded_state_flat),
        .ready        (perm_ready),
        .done         (done),
        .state_out_flat(permuted_state_flat)
    );

    // ready = permutation ready (the only real stall source)
    assign ready = perm_ready;

    // -----------------------------------------------------------------------
    // 3. Squeeze: first 256 bits of permuted state = SHA3-256 digest
    // -----------------------------------------------------------------------
    assign raw_hash_out = permuted_state_flat[255:0];

    // Endian-swap the output (always 256 bits)
    endian_swap_256 #(.DATA_BITS(256)) swap_out_inst (
        .in_data (raw_hash_out),
        .out_data(hash_out)
    );

endmodule
