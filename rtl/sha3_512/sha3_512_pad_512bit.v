`timescale 1ns / 1ps

module sha3_512_pad_512bit (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,          // Pulse high when 'message_512' is valid
    input  wire [511:0]  message_512,    // 512-bit input message (64 bytes)
    output reg           ready,          // High when module can accept a new message
    output reg           done,           // Pulsed high for 1 cycle when data is valid
    output reg  [575:0]  block_576,      // Final 576-bit padded rate block
    output reg  [1599:0] state_A_flat   
);

    // Local constants for padding values
    localparam [7:0] PAD_0X06 = 8'h06;
    localparam [7:0] PAD_0X80 = 8'h80;

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
            block_576     <= 576'd0;
            state_A_flat  <= 1600'd0;
        end else begin
            current_state <= next_state;

            case (current_state)
                STATE_IDLE: begin
                    done  <= 1'b0;
                    ready <= 1'b1;
                    
                    if (start) begin
                        ready <= 1'b0;
                        
                        // Verilog concatenation {MSB, ..., LSB} perfectly handles the mapping.
                        // We assemble the padding bytes and message instantly.
                        block_576 <= {
                            PAD_0X80,       // Bits [575:568]
                            48'd0,          // Bits [567:520] (six 0x00 bytes)
                            PAD_0X06,       // Bits [519:512]
                            message_512     // Bits [511:0]
                        };
                        
                        // state_A_flat is simply the block padded with 1024 capacity zeros.
                        state_A_flat <= {
                            1024'd0,        // Bits [1599:576] (Capacity)
                            PAD_0X80,       // Bits [575:568]
                            48'd0,          // Bits [567:520]
                            PAD_0X06,       // Bits [519:512]
                            message_512     // Bits [511:0]
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