`timescale 1ns / 1ps

module tb_sha3_512_pad;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [511:0] message_512;

    // Outputs
    wire ready;
    wire done;
    wire [575:0] block_576;
    wire [1599:0] state_A_flat;

    // Instantiate the Unit Under Test (UUT)
    sha3_512_pad_512bit uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .message_512(message_512), 
        .ready(ready), 
        .done(done), 
        .block_576(block_576), 
        .state_A_flat(state_A_flat)
    );

    // Clock Generation (100 MHz)
    always #5 clk = ~clk;

    // Generate Expected Golden References
    wire [575:0] expected_block = {
        8'h80,                  // End pad
        48'h000000000000,       // Zero pads
        8'h06,                  // Start pad
        {64{8'h42}}             // 64 bytes of 0x42
    };
    
    wire [1599:0] expected_state = {
        1024'd0,                // Capacity zeros
        expected_block          // Rate block
    };

    // Test Sequence
    initial begin
        // Initialize Inputs
        clk = 0;
        rst_n = 0;
        start = 0;
        message_512 = 0;

        // Apply Reset
        #20;
        rst_n = 1;
        #10;

        // Wait for module to be ready
        wait(ready == 1'b1);
        
        // Setup the test message (64 bytes of 0x42) and pulse start
        @(posedge clk);
        message_512 = {64{8'h42}}; 
        start = 1'b1;
        
        @(posedge clk);
        start = 1'b0; // De-assert start after 1 cycle

        // Wait for the padding to complete
        wait(done == 1'b1);
        @(posedge clk);

        // --- VERIFICATION ---
        $display("==================================================");
        $display("             SHA3-512 PADDING TEST                ");
        $display("==================================================");
        
        // Check block_576
        if (block_576 === expected_block) begin
            $display("[PASS] block_576 perfectly matches FIPS 202 spec.");
        end else begin
            $display("[FAIL] block_576 MISMATCH!");
            $display("Expected: %x", expected_block);
            $display("Got:      %x", block_576);
        end

        // Check state_A_flat
        if (state_A_flat === expected_state) begin
            $display("[PASS] state_A_flat perfectly matches FIPS 202 spec.");
        end else begin
            $display("[FAIL] state_A_flat MISMATCH!");
        end
        $display("==================================================");

        // End simulation
        #50;
        $finish;
    end

endmodule