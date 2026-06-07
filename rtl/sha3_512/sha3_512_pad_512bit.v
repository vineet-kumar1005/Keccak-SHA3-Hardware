`timescale 1ns / 1ps

module sha3_512_pad_512bit #(
    parameter MSG_BITS = 512
) (
    // imp - clk / rst_n kept in the port list for interface compatibility,
    // but are unused inside this module.
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  start,        // Pulse high when message_512 is valid
    input  wire [MSG_BITS-1:0]   message_512,  // Input message

    output wire                  ready,        // Always 1 — combinational pad is always ready
    output wire                  done,         // Equals start — output valid same cycle

    output wire [575:0]          block_576,    // 576-bit padded rate block
    output wire [1599:0]         state_A_flat  // 1600-bit initial Keccak state
);

    // -----------------------------------------------------------------------
    // Fixed SHA3-512 geometry
    // -----------------------------------------------------------------------
    localparam RATE_BITS      = 576; //size of input max for sha3-512
    localparam ZERO_FILL_BITS = RATE_BITS - MSG_BITS - 16; //to calculate 0s to be filled

    localparam [7:0] PAD_06 = 8'h06;
    localparam [7:0] PAD_80 = 8'h80;

    // -----------------------------------------------------------------------
    // Combinational padded rate block
    // -----------------------------------------------------------------------
    generate
        if (ZERO_FILL_BITS > 0) begin : gen_normal_pad
            assign block_576 = {
                PAD_80,
                {ZERO_FILL_BITS{1'b0}},
                PAD_06,
                message_512
            };
        end else begin : gen_adjacent_pad
            // MSG_BITS = 560: 0x06 and 0x80 are adjacent, no zero fill needed
            assign block_576 = {
                PAD_80,
                PAD_06,
                message_512
            };
        end
    endgenerate

    // Capacity zero-pad appended to form the full 1600-bit Keccak state
    assign state_A_flat = {1024'd0, block_576};

    // -----------------------------------------------------------------------
    // Handshake signals
    // -----------------------------------------------------------------------
    assign ready = 1'b1;   // always ready; no stall possible
    assign done  = start;  // output is valid the same cycle start is asserted

endmodule