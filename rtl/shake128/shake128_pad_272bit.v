`timescale 1ns / 1ps

module shake128_pad_272bit #(
    parameter MSG_BITS = 272
) (
    // clk / rst_n kept for interface compatibility — unused inside.
    input  wire                  clk,
    input  wire                  rst_n,
 
    input  wire                  start,        // Pulse high when message_272 is valid
    input  wire [MSG_BITS-1:0]   message_272,  // Input message (MSG_BITS wide)
 
    output wire                  ready,        // Always 1
    output wire                  done,         // Equals start — valid same cycle
 
    output wire [1343:0]         block_1344,   // 1344-bit padded rate block
    output wire [1599:0]         state_A_flat  // 1600-bit initial Keccak state
);
 
    // -----------------------------------------------------------------------
    // Fixed SHAKE128 geometry
    // -----------------------------------------------------------------------
    localparam RATE_BITS      = 1344;
    localparam ZERO_FILL_BITS = RATE_BITS - MSG_BITS - 16; // bits between 0x1F and 0x80
 
    localparam [7:0] PAD_1F = 8'h1F;   // SHAKE domain separator
    localparam [7:0] PAD_80 = 8'h80;   // pad end marker

    generate
        if (ZERO_FILL_BITS > 0) begin : gen_normal_pad
            assign block_1344 = {
                PAD_80,
                {ZERO_FILL_BITS{1'b0}},
                PAD_1F,
                message_272
            };
        end else begin : gen_adjacent_pad
            // MSG_BITS = RATE_BITS - 16 = 1328: 0x1F and 0x80 are adjacent
            assign block_1344 = {
                PAD_80,
                PAD_1F,
                message_272
            };
        end
    endgenerate
 
    // Capacity zero-pad to form the full 1600-bit Keccak state
    assign state_A_flat = {256'd0, block_1344};
 
    // -----------------------------------------------------------------------
    // Handshake
    // -----------------------------------------------------------------------
    assign ready = 1'b1;
    assign done  = start;
 
endmodule