`timescale 1ns / 1ps

module shake128_pad_272bit (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,          // Pulse high when 'message_272' is valid
    input  wire [271:0]  message_272,    // 272-bit input message (34 bytes)
    output reg           ready,          // High when module can accept a new message
    output reg           done,           // Pulsed high for 1 cycle when data is valid
    output reg  [1343:0] block_1344,     // Final 1344-bit padded rate block (SHAKE128)
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
            block_1344    <= 1344'd0;
            state_A_flat  <= 1600'd0;
        end else begin
            current_state <= next_state;

            case (current_state)
                STATE_IDLE: begin
                    done  <= 1'b0;
                    ready <= 1'b1;
                    
                    if (start) begin
                        ready <= 1'b0;
                        
                        // Assemble the SHAKE128 1344-bit rate block
                        block_1344 <= {
                            PAD_0X80,       // Bits [1343:1336]
                            1056'd0,        // Bits [1335:280] (132 bytes of zeros)
                            PAD_0X1F,       // Bits [279:272]
                            message_272     // Bits [271:0]
                        };
                        
                        // state_A_flat pads the 1344-bit block with 256 Capacity zeros
                        state_A_flat <= {
                            256'd0,         // Bits [1599:1344] (SHAKE128 Capacity)
                            PAD_0X80,       // Bits [1343:1336]
                            1056'd0,        // Bits [1335:280]
                            PAD_0X1F,       // Bits [279:272]
                            message_272     // Bits [271:0]
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