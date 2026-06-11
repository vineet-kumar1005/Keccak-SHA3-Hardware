`timescale 1ns / 1ps

module sha3_512_top #(
    parameter MSG_BITS = 512
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [MSG_BITS-1:0]   message_in,
    output wire                  ready,
    output wire                  done,
    output wire [511:0]          hash_out
);

    wire [MSG_BITS-1:0] swapped_message_in;
    wire [575:0]        block_576_unused;
    wire [1599:0]       padded_state_flat;
    wire                pad_done;           // = start (combinational pass-through)
    wire [1599:0]       permuted_state_flat;
    wire [511:0]        raw_hash_out;
    wire                perm_ready;

    // -----------------------------------------------------------------------
    // 0. Endian-swap the input
    // -----------------------------------------------------------------------
    endian_swap_512 #(.MSG_BITS(MSG_BITS)) swap_in_inst (
        .in_data (message_in),
        .out_data(swapped_message_in)
    );

    // -----------------------------------------------------------------------
    // 1. Padding — purely combinational, no FSM
    //    pad_done = start (same cycle), state_A_flat valid whenever message is.
    // -----------------------------------------------------------------------
    sha3_512_pad_512bit #(.MSG_BITS(MSG_BITS)) padding_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .message_512(swapped_message_in),
        .ready      (),                    // always 1 — unused here
        .done       (pad_done),
        .block_576  (block_576_unused),    // unused at top level
        .state_A_flat(padded_state_flat)
    );

    // -----------------------------------------------------------------------
    // 2. Keccak-f[1600] permutation — 24-round FSM (unchanged)
    //    Latches state_A_flat on the posedge where pad_done (= start) is high.
    // -----------------------------------------------------------------------
    keccak_permutation perm_inst (
        .clk          (clk),
        .rst_n        (rst_n),
        .start        (pad_done),          // = start, no extra cycle wasted
        .state_in_flat(padded_state_flat),
        .ready        (perm_ready),
        .done         (done),
        .state_out_flat(permuted_state_flat)
    );

    // ready = permutation ready (the only real stall source now)
    assign ready = perm_ready;

    // -----------------------------------------------------------------------
    // 3. Squeeze + output endian swap
    // -----------------------------------------------------------------------
    assign raw_hash_out = permuted_state_flat[511:0];

    endian_swap_512 #(.MSG_BITS(512)) swap_out_inst (
        .in_data (raw_hash_out),
        .out_data(hash_out)
    );

endmodule