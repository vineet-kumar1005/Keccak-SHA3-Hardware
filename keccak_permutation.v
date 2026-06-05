`timescale 1ns / 1ps

module keccak_permutation (
    input  wire          clk,
    input  wire          rst_n,
    input  wire          start,          // Pulse high to begin the 24 rounds
    input  wire [1599:0] state_in_flat,  // The initial state (e.g., from the padding module)
    output reg           ready,          // High when ready to accept a new state
    output reg           done,           // Pulsed high for 1 cycle when 24 rounds are complete
    output reg  [1599:0] state_out_flat  // The fully permuted state
);

    localparam STATE_IDLE = 2'd0;
    localparam STATE_CALC = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] current_state;
    reg [4:0] round_idx;      // Counts 0 to 23
    reg [1599:0] state_reg;   // The core loopback register

    wire [1599:0] round_out;  // Combinational output from the round module

    // Instantiate the Single Combinational Round
    keccak_round core_round (
        .state_in_flat(state_reg),
        .round_idx(round_idx),
        .round_out_flat(round_out)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state  <= STATE_IDLE;
            round_idx      <= 5'd0;
            ready          <= 1'b1;
            done           <= 1'b0;
            state_out_flat <= 1600'd0;
            state_reg      <= 1600'd0;
        end else begin
            case (current_state)
                
                STATE_IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        current_state <= STATE_CALC;
                        ready         <= 1'b0;
                        round_idx     <= 5'd0;
                        state_reg     <= state_in_flat; 
                    end
                end
                
                STATE_CALC: begin
                    state_reg <= round_out;
                    
                    if (round_idx == 5'd23) begin
                        // 24 rounds complete (0 to 23)
                        current_state <= STATE_DONE;
                    end else begin
                        // Increment round counter
                        round_idx <= round_idx + 1'b1;
                    end
                end
                
                STATE_DONE: begin
                    //final permuted state
                    state_out_flat <= state_reg;
                    done           <= 1'b1;
                    ready          <= 1'b1;
                    current_state  <= STATE_IDLE;
                end
                
                default: current_state <= STATE_IDLE;
                
            endcase
        end
    end
    

endmodule