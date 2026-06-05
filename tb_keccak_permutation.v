`timescale 1ns / 1ps

module tb_keccak_permutation;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [1599:0] state_in_flat;

    // Outputs
    wire ready;
    wire done;
    wire [1599:0] state_out_flat;

    // Instantiate the Unit Under Test (UUT)
    keccak_permutation uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .state_in_flat(state_in_flat),
        .ready(ready),
        .done(done),
        .state_out_flat(state_out_flat)
    );

    // Clock generation: 100 MHz
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        
        // Standard all-zero test state
        state_in_flat = 1600'd0; 

        // Wait 100 ns for global reset to finish
        #100;
        
        // Release reset
        rst_n = 1;
        #20;
        
        // Wait until UUT is in STATE_IDLE and ready
        wait(ready == 1'b1);
        
        // Align to clock edge, provide input, and pulse start
        @(posedge clk);
        start = 1'b1;
        
        @(posedge clk);
        start = 1'b0; // Pull start down after 1 cycle
        
        // Wait for the FSM to pulse the done signal
        wait(done == 1'b1);
        
        // Display results on the next cycle
        @(posedge clk);
        $display("========================================");
        $display("Keccak Permutation Complete (24 Rounds)");
        $display("========================================");
        $display("Lane (0,0) [ 63:  0]: %h", state_out_flat[63:0]);
        $display("Lane (1,0) [127: 64]: %h", state_out_flat[127:64]);
        $display("Lane (2,0) [191:128]: %h", state_out_flat[191:128]);
        $display("========================================");
        
        // Finish simulation
        #50;
        $finish;
    end

endmodule