`timescale 1ns / 1ps

module shake256_pad_264bit #(
    parameter MSG_BITS = 264
) (
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire                  start,        // Pulse high when message_264 is valid
    input  wire [MSG_BITS-1:0]   message_264,  // Input message (MSG_BITS wide)

    output wire                  ready,        // Always 1
    output wire                  done,         // Equals start — valid same cycle

    output wire [1087:0]         block_1088,   // 1088-bit padded rate block
    output wire [1599:0]         state_A_flat  // 1600-bit initial Keccak state
);

    // -----------------------------------------------------------------------
    // Fixed SHAKE256 geometry
    // -----------------------------------------------------------------------
    localparam RATE_BITS      = 1088;
    localparam ZERO_FILL_BITS = RATE_BITS - MSG_BITS - 16; // bits between 0x1F and 0x80

    localparam [7:0] PAD_1F = 8'h1F;   // SHAKE domain separator
    localparam [7:0] PAD_80 = 8'h80;   // pad end marker

    // -----------------------------------------------------------------------
    // Combinational padded rate block
    // -----------------------------------------------------------------------
    generate
        if (ZERO_FILL_BITS > 0) begin : gen_normal_pad
            assign block_1088 = {
                PAD_80,
                {ZERO_FILL_BITS{1'b0}},
                PAD_1F,
                message_264
            };
        end else begin : gen_adjacent_pad
            // MSG_BITS = RATE_BITS - 16 = 1072: 0x1F and 0x80 are adjacent
            assign block_1088 = {
                PAD_80,
                PAD_1F,
                message_264
            };
        end
    endgenerate

    // Capacity zero-pad to form the full 1600-bit Keccak state
    assign state_A_flat = {512'd0, block_1088};

    // -----------------------------------------------------------------------
    // Handshake
    // -----------------------------------------------------------------------
    assign ready = 1'b1;
    assign done  = start;

endmodule