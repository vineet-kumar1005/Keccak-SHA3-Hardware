`timescale 1ns / 1ps

module shake256_pad_264bit (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,          // Pulse high when 'message_264' is valid
    input  wire [263:0]  message_264,    // 264-bit input message (33 bytes)
    output reg           ready,          // High when module can accept a new message
    output reg           done,           // Pulsed high for 1 cycle when data is valid
    output reg  [1087:0] block_1088,     // Final 1088-bit padded rate block (SHAKE256)
    output reg  [1599:0] state_A_flat    // Full 1600-bit state ready for the permutation
);

    // Local constants for SHAKE padding values
    localparam [7:0] PAD_0X1F = 8'h1F; // SHAKE domain suffix + start of pad
    localparam [7:0] PAD_0X80 = 8'h80; // End of pad

    // State Machine parameters
    localparam STATE_IDLE  = 1'b0;
    localparam STATE_PAD   = 1'b1;
    reg current_state, next_state;

    // Next State Logic
    always @(*) begin
        case (current_state)
            STATE_IDLE: begin
                if (start)
                    next_state = STATE_PAD;
                else
                    next_state = STATE_IDLE;
            end
            STATE_PAD: begin
                next_state = STATE_IDLE; // Process takes exactly 1 clock cycle
            end
            default: next_state = STATE_IDLE;
        endcase
    end

    // Sequential Logic Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_IDLE;
            ready         <= 1'b1;
            done          <= 1'b0;
            block_1088    <= 1088'd0;
            state_A_flat  <= 1600'd0;
        end else begin
            current_state <= next_state;

            case (current_state)
                STATE_IDLE: begin
                    done  <= 1'b0;
                    ready <= 1'b1;
                    
                    if (start) begin
                        ready <= 1'b0;
                        
                        // Assemble the SHAKE256 1088-bit rate block
                        block_1088 <= {
                            PAD_0X80,       // Bits [1087:1080]
                            808'd0,         // Bits [1079:272] (101 bytes of zeros)
                            PAD_0X1F,       // Bits [271:264]
                            message_264     // Bits [263:0]
                        };
                        
                        // state_A_flat pads the 1088-bit block with 512 Capacity zeros
                        state_A_flat <= {
                            512'd0,         // Bits [1599:1088] (SHAKE256 Capacity)
                            PAD_0X80,       // Bits [1087:1080]
                            808'd0,         // Bits [1079:272]
                            PAD_0X1F,       // Bits [271:264]
                            message_264     // Bits [263:0]
                        };
                    end
                end

                STATE_PAD: begin
                    // Data is now latched and valid. Pulse done.
                    done  <= 1'b1;
                    ready <= 1'b1; // Ready to accept next on the following cycle
                end
            endcase
        end
    end

endmodule