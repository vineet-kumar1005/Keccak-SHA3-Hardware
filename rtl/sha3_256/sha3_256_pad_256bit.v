`timescale 1ns / 1ps

// SHA3-256 Padding Module — fully combinational, no FSM.
//
// Parameters
// ----------
//   MSG_BITS  : Width of the input message in bits.
//               Must be a multiple of 8, and satisfy: MSG_BITS < RATE_BITS (1088).
//               Default = 256 (32 bytes).
//
// Constants (fixed for SHA3-256, do not change)
// -----------------------------------------------
//   RATE_BITS = 1088  (136 bytes — SHA3-256 rate = 1600 - 2×256)
//   CAP_BITS  =  512  ( 64 bytes — SHA3-256 capacity)
//
// Padding rule (FIPS 202 §B.2 for SHA3):
//   [message] [0x06] [0x00 ... 0x00] [0x80]
//   0x06 = SHA3 domain separator (NOT 0x1F which is SHAKE)
//   0x80 = pad end marker at the last byte of the rate block
//
// Timing
// ------
//   All outputs are purely combinational — zero clock latency.
//   ready = 1 always.
//   done  = start (output valid the same cycle start is asserted).
//   The downstream keccak_permutation registers state_A_flat on the posedge
//   where it sees start/done high, so no extra pipeline stage is needed.

module sha3_256_pad_256bit #(
    parameter MSG_BITS = 256
) (
    // clk / rst_n kept for interface compatibility — unused inside.
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  start,        // Pulse high when message_256 is valid
    input  wire [MSG_BITS-1:0]   message_256,  // Input message (MSG_BITS wide)

    output wire                  ready,        // Always 1
    output wire                  done,         // Equals start — valid same cycle

    output wire [1087:0]         block_1088,   // 1088-bit padded rate block
    output wire [1599:0]         state_A_flat  // 1600-bit initial Keccak state
);

    // -----------------------------------------------------------------------
    // Fixed SHA3-256 geometry
    // -----------------------------------------------------------------------
    localparam RATE_BITS      = 1088;
    localparam ZERO_FILL_BITS = RATE_BITS - MSG_BITS - 16; // bits between 0x06 and 0x80

    localparam [7:0] PAD_06 = 8'h06;   // SHA3 domain separator
    localparam [7:0] PAD_80 = 8'h80;   // pad end marker

    // -----------------------------------------------------------------------
    // Combinational padded rate block
    //
    // Bit layout (LSB = bit 0):
    //   [MSG_BITS-1 : 0]              — message
    //   [MSG_BITS+7 : MSG_BITS]       — 0x06
    //   [RATE_BITS-9 : MSG_BITS+8]    — zero fill (may be 0 bits when adjacent)
    //   [RATE_BITS-1 : RATE_BITS-8]   — 0x80
    // -----------------------------------------------------------------------
    generate
        if (ZERO_FILL_BITS > 0) begin : gen_normal_pad
            assign block_1088 = {
                PAD_80,
                {ZERO_FILL_BITS{1'b0}},
                PAD_06,
                message_256
            };
        end else begin : gen_adjacent_pad
            // MSG_BITS = RATE_BITS - 16 = 1072: 0x06 and 0x80 are adjacent
            assign block_1088 = {
                PAD_80,
                PAD_06,
                message_256
            };
        end
    endgenerate

    // Capacity zero-pad to form the full 1600-bit Keccak state
    assign state_A_flat = {512'd0, block_1088};

    // -----------------------------------------------------------------------
    // Handshake — purely combinational
    // -----------------------------------------------------------------------
    assign ready = 1'b1;
    assign done  = start;

endmodule
