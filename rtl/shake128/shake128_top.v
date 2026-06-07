`timescale 1ns / 1ps

module shake128_top #(
    parameter MSG_BITS = 272
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  start,
    input  wire [MSG_BITS-1:0]   message_in,   // Raw user input (MSG_BITS wide)
    output wire                  ready,         // From permutation — the only stall source
    output wire                  done,
    output wire [1343:0]         hash_out       // SHAKE128 output (always 1344 bits)
);

    // -----------------------------------------------------------------------
    // Internal wires
    // -----------------------------------------------------------------------
    wire [MSG_BITS-1:0] swapped_message_in;
    wire [1343:0]       block_1344_unused;
    wire [1599:0]       padded_state_flat;
    wire                pad_done;               // = start (combinational)
    wire [1599:0]       permuted_state_flat;
    wire [1343:0]       raw_hash_out;
    wire                perm_ready;

    // -----------------------------------------------------------------------
    // 0. Endian-swap the input (MSG_BITS wide)
    // -----------------------------------------------------------------------
    endian_swap #(.DATA_BITS(MSG_BITS)) swap_in_inst (
        .in_data (message_in),
        .out_data(swapped_message_in)
    );

    // -----------------------------------------------------------------------
    // 1. Padding — purely combinational, no FSM
    //    pad_done = start (same cycle); state_A_flat valid whenever message is.
    // -----------------------------------------------------------------------
    shake128_pad_272bit #(.MSG_BITS(MSG_BITS)) padding_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .message_272(swapped_message_in),
        .ready      (),                    // always 1 — unused here
        .done       (pad_done),
        .block_1344 (block_1344_unused),   // unused at top level
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
    // 3. Squeeze: take the first RATE_BITS (1344) of the permuted state
    // -----------------------------------------------------------------------
    assign raw_hash_out = permuted_state_flat[1343:0];

    // Endian-swap the output (1344 bits)
    endian_swap #(.DATA_BITS(1344)) swap_out_inst (
        .in_data (raw_hash_out),
        .out_data(hash_out)
    );

endmodule